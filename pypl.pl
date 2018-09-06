#!/usr/bin/perl -w
use POSIX 'floor';
# Starting point for COMP[29]041 assignment 1
# http://www.cse.unsw.edu.au/~cs2041/assignments/pypl
# written by z5119672@unsw.edu.au September 2017

#A function to identify what this line is going to express. Then return
#the id of this line
sub printFunctionCheck{
    my $line = $_[0];
    if ($line =~ m/(^\s*)print *\((.*)?\)/) {
        my $spaces = $1; #spaces before print function call
        my $context = $2; #the context supposed to be printed wihtout bracket
        my $newLineFlag = 1; 
        #if match end='' newLineFlag set down
        if($context =~ m/, ?end ?= ?'/){
            $context =~ s/, ?end ?= ?'//;
            $context =~ s/'$//;
            $newLineFlag = 0;
        }
        #Split context by ','. To see if it's multi or single things to print
        my @vars = split /,/, $context;
        #$#vars > 0 means multi things to print
        if($#vars > 0){
        #Go through everythings waiting to print by
            foreach my $i (@vars){
        #Delete the useless space at the beginning
                $i =~ s/^ //;
        #if there's still something after a word and space, It may be an 
        #operator. Format the operator 
                if($i =~ m/^\s*\w+ *?[^,]/){
                    $i =~ s/\+/ \+ /g;
                    $i =~ s/\-/ \- /g;
                    $i =~ s/\*/ \* /g;
                    $i =~ s/\/\//\//g;
                    $i =~ s/\// \/ /g;
                    $i =~ s/\%/ \% /g;
                    $i =~ s/\(/ \( /g;
                    $i =~ s/\)/ \) /g;
                    $i =~ s/ +/ /g;
        #Split by space, add '$' before variable
                    my @tempVal = split / /, $i;
                    foreach my $j (@tempVal){
                        if($j =~ m/^[a-z|A-Z]+/){
                            $j = "\$$j";
                        }
                    }
                    $i = join " ", @tempVal;
        #If this term is just a single variable, just add '$' before it
                }elsif($i =~ m/^\s*(\w+)$/){
                    $i = $1;
                    $i = "\$$i";
                }
            }
            $context = join ", ", @vars;
        #Check newLineFlag to decide whether print \n
            if($newLineFlag == 1){
                print "print $context, \"\\n\";";
            }else{
                print "print $context\";";
            }
        #If the context is single thing to print
        }else{
            if($context =~ m/^\w+/){
        #Format operator as usual
                if($context =~ m/^\s*\w+ *[\+\-\*\/\%]/){
                    $context =~ s/ //g;
                    $context =~ s/\+/ \+ /g;
                    $context =~ s/\-/ \- /g;
                    $context =~ s/\*/ \* /g;
                    $context =~ s/\/\//\//g;
                    $context =~ s/\// \/ /g;
                    $context =~ s/\%/ \% /g;
                    $context =~ s/\(/ \( /g;
                    $context =~ s/\)/ \) /g;
                    $context =~ s/ +/ /g;
                }
        #Add '$' before variables
                my @tempVal2 = split / /, $context;
                foreach my $k (@tempVal2){
                    if($k =~ m/^[a-z|A-Z]+/){
                        $k = "\$$k";
                    }
        #Handle the indexing situiation e.g list[i] -> $list[$i]
                    if($k =~ m/\w+\[([a-z|A-Z]+)\]/){
                        $k =~ s/\[/\[\$/;                        
                    }
                }
                $context = join " ", @tempVal2;
        #Check new line as usual
                if($newLineFlag == 1){
                    print $spaces, "print $context, \"\\n\";";
                }else{
                    print $spaces, "print $context;";
                }
        #Term is "string" situiation
            }else{
                $context =~ s/"//g;
                if($newLineFlag == 1){
                    print $spaces, "print \"$context\\n\";";
                }else {
                    print $spaces, "print \"$context\";";
                }
            }
        }
    }
}
#As long as matched '=' in $line this function will be called
sub equationLineCheck{
    my $line = $_[0];
    #Double check this line is a equation
    if($line =~ m/^(\s*)(\w+) ?= ?(.*)$/){
        chomp $line;
        my $spaces = $1;#spaces in the front
        my $var = $2;# Term on left hand side, i.e.varibale name
        my $rest = $3;#things after the euqation sign
        #Format operator as usual
        if($rest =~ m/[\+\-\*\/\%]/){
            $rest =~ s/ //g;
            if($rest =~ m/\w+\/\/\w+/){
                $rest =~ s/\/\//\//;
            }
            $rest =~ s/\+/ \+ /g;
            $rest =~ s/\-/ \- /g;
            $rest =~ s/\*/ \* /g;
            $rest =~ s/\// \/ /g;
            $rest =~ s/\%/ \% /g;
            $rest =~ s/\(/ \( /g;
            $rest =~ s/\)/ \) /g;
            $rest =~ s/ +/ /g;
        }
        #If just set up a empty list e.g. a=[];
        #Use hash table $varType{$var} to store the type of the variable
        if($rest =~ m/^\[\]$/){
            $line = "";
            $varType{$var} = "list";
            return $line;
        #Handle int() situiation set $varType{$var} = "int"
        }elsif($rest =~ m/int\((.+)?\)/){
            $varType{$var} = "int";
            $var = "\$$var";
            $line = "$spaces$var = $1";
            return $line;
        #Handle string situiation e.g. a = "comp2041"
        }elsif($rest =~ m/^\"[^\"]*\"$/){
            $varType{$var} = "string";
            $var = "\$$var";
            $line = "$spaces$var = $rest";
        #Handle calculating type euqation
        }elsif($rest =~ m/(\w+) ?[\+\-\*\/\%] ? (\w+)/){
            my @tempRest = split / /, $rest;
        #Go through every variable on the right hand side to see what type
        #it is then define the type of left hand side variable
            foreach my $i (@tempRest){
                $i =~ s/^\$//;
                $i =~ s/^\@//;
        #See each variable on right hand side is a list or string or 
        #start with a '$'revised by me as a line count or <STDIN>
        #else just numbers
                if($i =~ m/^[a-z|A-Z]+/){
        #If right hand side is a list then left hand side is the element
        #count of the list
        #list assignment will not be pased here because operator was required
        #in the regex
                    if($varType{$i} && $varType{$i} eq "list"){
                        $varType{$var} = "int";
                        $i = "\@$i";
        #If right hand side is a string then left hand side is a string 2
                    }elsif($varType{$i} && $varType{$i} eq "string"){
                        $varType{$var} = "string";
                        $i = "\$$i";
                    }else{
                        $i = "\$$i";
                    }
                }
            }
            $rest = join " ", @tempRest;
            $var = "\$$var";
            $line = "$spaces$var = $rest";
        #The left hand side variable was assigned to a sys.stdin.readline()
        #Something like a = $lines will be passed in here. $a here for 
        #counting lines. So it was set as int type
        }elsif($rest =~m/\$/){
            $varType{$var} = "int";
            $var = "\$$var";
            $line = "$spaces    $var++";
            $spaces =~ s/\s/ /g;
            @Nspaces = split//, $spaces;
            unshift @indentation, $#Nspaces+1;
        #Something like a= <STDIN> willl be passed here $var is string
        }elsif($rest =~ /<STDIN>/){
            $varType{$var} = "string";
            $var = "\$$var";
            $line = "$spaces$var = <STDIN>";
        #RHS are only numbers
        }else{
            $varType{$var} = "int";
            $var = "\$$var";
            $line = "$var = $rest";
        }
    }
    return $line;
}

#main
while ($line = <>) {
    if ($line =~ /^#!/ && $. == 1) {

        # translate #! line

        print "#!/usr/bin/perl -w\n";

    } elsif ($line =~ /^\s*#/ || $line =~ m/^\s*$/) {

        # Blank & comment lines can be passed unchanged

        print $line;

    } elsif ($line =~ /(^\s*)print *\((.*)\)/) {
        $indenbuffer = $1;        #Spaces in the front
        $line =~ m/(\s*#.*)/; #If there's comments
        $comment = $1; #Store in $comment
            $line =~ s/\s*#.*//; #Delete all the comment
        @Nspaces = split //, $indenbuffer;#Count spaces in the front. If 
        #spaces is less than the lastet indentation that menas this line
        #finished more than one if|while|elsif statements.Then print out
        #all the }\n at correct place.
        while(@indentation && $#Nspaces + 1 < $indentation[0]){
            $i=0;
            while($i < $indentation[0]){
                    print " ";
                    $i+=1;
            }
            print "}\n";
            shift @indentation;

        }
        #If this line just finished the latest if|while|elsif statements
        if(@indentation && $indentation[0] == $#Nspaces+1){
                print"$indenbuffer}\n";
                shift @indentation;
        }
        printFunctionCheck($line);#pass to print function to print this line out
        if($comment){#print out comments
            print $comment, "\n";
        }else{
            print "\n";
        }
    #If this line is not a print, a comment, or empty line
    } else {
        $line =~ m/.*?(\s*#.*)/;
        $comment = $1;#store comments
        $line =~ s/\s*#.*//;#delete comments
        $line =~ m/(^\s*)/;#check indentation
        $indenbuffer = $1;
        @Nspaces = split //, $indenbuffer;
        while(@indentation && $#Nspaces+1 < $indentation[0]){
                $i=0;
                while($i < $indentation[0]){
                    print " ";
                    $i+=1;
                }
                print "}\n";
                shift @indentation;
        }
        if(@indentation && $indentation[0] == $#Nspaces+1){
            if($line =~ m/else:/){
                print"$indenbuffer} else {";
                if($comment){
                    print "$comment", "\n";
                }else{
                    print "\n";
                }
            }elsif($line =~ m/elif .*?:/){
                $line =~ s/^(\s)*//;
                print"$indenbuffer} ";
            }
            else{
                print"$indenbuffer}\n";
                shift @indentation;
            }

        }
        #Handle len($x); $x could be a list , but it was classed as 'sys'
        #type by me if $x is stdin.readlines()
        if($line =~ m/len\((.+)?\)/){
            $target = $1;
        #add '@' before variable name
            if($varType{$target} && $varType{$target} eq "list"){
                $target = "\@$target";
                $line =~ s/len\(.+\)/$target/;
        #add '$' before variable name which will be used in eqCheck function
            }elsif($varType{$target} && $varType{$target} eq "sys"){
                $target = "\$$target";
                $line =~ s/len\(.+\)/$target/;                
            }
        }
        if($line =~ m/(\s*)sys\.stdout\.write\((.*?)\)/){
            $spaces = $1;
            $context = $2;
            $line =~ s/sys\.stdout\.write/print/;
            chomp $line;
            print $spaces,"print ",$context, ";";
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }
        }
        if($line =~ m/(\s*)(\w+) ?= ?sys\.stdin\.readlines\(\)/){
            $spaces = $1;
            $var = $2;
            $varType{$var} = "sys";
            $line = "";
            print $spaces, "while(<STDIN>) {\n";
        }
        #Replace sys.stdin.readline() with <STDIN> which will be recognized
        #in eqCheck function
        if($line =~ m/(\s*)(\w+) ?= ?.*?sys\.stdin\.readline\(\)/){
            $line =~ s/sys\.stdin\.readline\(\)/<STDIN>/;
        }
        #Handle .append()
        if($line =~ m/(\s*)([a-z|A-Z]+)\.append\(([a-z|A-Z]+)\)/){
            $spaces = $1;
            $list = $2;
            $var = $3;
            $list = "\@$list";
            $var = "\$$var";
            print $spaces, "push ", $list, ", ", $var, "\n";
        }
        #See if line is simple variable setup or calculation
        if($line =~ m/^\s*(\w+) ?= ?(.*)$/){
            $line = equationLineCheck($line);
            if($line){
                print "$line;";
            }
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }
        }
        #See if line is single line if,while statement
        if($line =~ m/(^\s*)(while|if|elif) (.*)?: *?(\S+)/){
            $line =~ m/(^\s*)(while|if) (.*)?: *?(.+)/;
            $spaces = $1;
            $condition = $2;
            $expr = $3;
            $lineSplit = $4;
    #store spaces before line as usual
            $spaces =~ s/\s/ /g;
            @Nspaces = split //, $spaces;
            unshift @indentation, $#Nspaces+1;
    #Replace and, or , not as \\and\\. In case matched $candy $north stuff
    #Replace operator as string operator as default
            $expr =~ s/ and/\\and\\/g;
            $expr =~ s/ or/\\or\\/g;
            $expr =~ s/ not/\\not\\/g;
            $expr =~ s/ //g;
            $expr =~ s/>=/ \\ge /g;
            $expr =~ s/<=/ \\le /g;
            $expr =~ s/==/ \\eq /g;
            $expr =~ s/!=/ \\ne /g;
            $expr =~ s/</ \\lt /g;
            $expr =~ s/>/ \\gt /g;
            $expr =~ s/\(/ \( /g;
            $expr =~ s/\)/ \) /g;
            $expr =~ s/\\and\\/ and /g;
            $expr =~ s/\\or\\/ or /g;
            $expr =~ s/\\not\\/ not /g;
            $expr =~ s/ +/ /g;
            @temp = split / /, $expr;
            $intcmpFlag = 0;
            $stringcmpFlag = 0;
    #If matched logical operator the type of compared variable may change
    #Reset flag
            foreach $i (@temp){
                if($i eq "and" || $i eq "or" || $i eq "not"){
                    $intcmpFlag = 0;
                    $stringcmpFlag = 0;
    #Handle (value1 +value2) < value3 situiation. i.e. dealing with bracket
                }elsif($i =~ m/^\(([a-z|A-Z]+)/){
                    $i =~ s/\(//;
                    if($varType{$i} && $varType{$i} eq "int"){
                        $intcmpFlag = 1;
                    }elsif($varType{$i} && $varType{$i} eq "string"){
                        $stringcmpFlag = 1;
                    }
                    $i = "(\$$1";
                }elsif($i =~ m/^[a-z|A-Z]+/){
    #Check $varType to see the type of compared variable and set flag
                    if($varType{$i} && $varType{$i} eq "int"){
                        $intcmpFlag = 1;
                    }elsif($varType{$i} && $varType{$i} eq "string"){
                        $stringcmpFlag = 1;
                    }
                    $i = "\$$i";
                }else{
    #If compared variable are numbers indeed, subs string operators with
    #numeric
                    if($stringcmpFlag == 0 && $intcmpFlag == 1){
                        $i =~ s/\\gt/>/;
                        $i =~ s/\\ge/>=/;
                        $i =~ s/\\eq/==/;
                        $i =~ s/\\ne/!=/;
                        $i =~ s/\\lt/</;
                        $i =~ s/\\le/<=/;
                    }else{
                        $i =~ s/^\\//;
                    }
                }
            }
            $expr = join " ", @temp;
            $condition = "$spaces$condition\($expr\){";
            print $condition;
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }
            $spaces = "    $spaces";
            #code after :. Split them and check everyone
            @lineSplit = split /;/, $lineSplit;
            foreach $i (@lineSplit){
                $i =~ s/^ *//;
                if ($i =~ m/^\s*print *\((.*)\)/) {
                    print $spaces;
                    printFunctionCheck($i);
                    print "\n";
                }elsif($i =~ m/^\s*(\w+) ?= ?(.*)$/){
                    print $spaces;
                    $i = equationLineCheck($i);
                    print "$i;\n";                
                }elsif($i =~ m/^break$/){
                    print $spaces, "last;\n";
                }elsif($i =~ m/^continue$/){
                    print $spaces, "next;\n";
                }                   
            }
        }
        #Single line and multi line if while statement are used the same
        #algorithm. All comments was saved and deleted as before.
        #Just chekc if there is still something but not spaces after ':'
        #Then this line is a multi line if, while statement
        if($line =~ m/^(\s*)(while|if|elif) (.*)? *?: *?\s*$/){
            $spaces = $1;
            $condition = $2;
            if($condition eq "elif"){
                $condition = "elsif";
            }
            $expr = $3;
            $expr =~ s/ and/\\and\\/g;
            $expr =~ s/ or/\\or\\/g;
            $expr =~ s/ not/\\not\\/g;
            $expr =~ s/ //g;
            $expr =~ s/>=/ \\ge /g;
            $expr =~ s/<=/ \\le /g;
            $expr =~ s/==/ \\eq /g;
            $expr =~ s/!=/ \\ne /g;
            $expr =~ s/</ \\lt /g;
            $expr =~ s/>/ \\gt /g;
            $expr =~ s/\(/ \( /g;
            $expr =~ s/\)/ \) /g;
            $expr =~ s/\\and\\/ and /g;
            $expr =~ s/\\or\\/ or /g;
            $expr =~ s/\\not\\/ not /g;
            $expr =~ s/ +/ /g;
            if($line !~ m/elif .*?:/){
                $spaces =~ s/\s/ /g;
                @Nspaces = split //, $spaces;
                unshift @indentation, $#Nspaces+1;
            }
            @temp = split / /, $expr;
            $intcmpFlag = 0;
            $stringcmpFlag = 0;
            foreach $i (@temp){
                if($i eq "and" || $i eq "or" || $i eq "not"){
                    $intcmpFlag = 0;
                    $stringcmpFlag = 0;
                }elsif($i =~ m/^\(([a-z|A-Z]+)/){
                    $i =~ s/\(//;
                    if($varType{$i} && $varType{$i} eq "int"){
                        $intcmpFlag = 1;
                    }elsif($varType{$i} && $varType{$i} eq "string"){
                        $stringcmpFlag = 1;
                    }
                    $i = "(\$$1";
                }elsif($i =~ m/^[a-z|A-Z]+/){
                    if($varType{$i} && $varType{$i} eq "int"){
                        $intcmpFlag = 1;
                    }elsif($varType{$i} && $varType{$i} eq "string"){
                        $stringcmpFlag = 1;
                    }
                    $i = "\$$i";
                }else{
                    if($stringcmpFlag == 0 && $intcmpFlag == 1){
                        $i =~ s/\\gt/>/;
                        $i =~ s/\\ge/>=/;
                        $i =~ s/\\eq/==/;
                        $i =~ s/\\ne/!=/;
                        $i =~ s/\\lt/</;
                        $i =~ s/\\le/<=/;
                    }else{
                        $i =~ s/^\\//;
                    }
                }
            }
            $expr = join " ", @temp;
            $condition = "$spaces$condition\($expr\){";
            print $condition;
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }
        }
    #Handle for lines
        if($line =~ m/(\s*)for ([a-z|A-Z]+) in (.*):/){
            $spaces = $1;
            $expr = $2;
            $rest = $3;
            $spaces =~ s/\s/ /g;
            @Nspaces = split //, $spaces;
            unshift @indentation, $#Nspaces+1;
            $expr = "\$$expr";
    #$rest = range(oneArg), or sys.stdin
            if($rest =~ m/range\((\w+)\)/){
                $range = $1;
    #Handle range(letters)
                if($range =~ m/^[a-z|A-Z]/){
                    print $spaces, "for($expr=0;$expr<\$$range;$expr++) {"
    #Handle range(number)
                }else{
                    print $spaces, "for($expr=0;$expr<$1;$expr++) {"
                }
    #$rest = range(two, numbers) situiation
            }elsif($rest =~ m/range\(([0-9]+.*?), ?([0-9]+.*?)\)/){
                $from = $1;
                $to = $2;
                $to = $to - 1;
                print $spaces, "foreach $expr ($from..$to) {";
    #$rest = range(two, letters) situiation
            }elsif($rest =~ m/range\((.+)?, (.+)?\)/){
                $from = $1;
                $to = $2;
                $from =~ s/\+/ \+ /g;
                $from =~ s/\-/ \- /g;
                $from =~ s/\*/ \* /g;
                $from =~ s/\/\//\//g;
                $from =~ s/\// \/ /g;
                $from =~ s/\%/ \% /g;
                $from =~ s/\(/ \( /g;
                $from =~ s/\)/ \) /g;
                $from =~ s/ +/ /g;
                $to =~ s/\+/ \+ /g;
                $to =~ s/\-/ \- /g;
                $to =~ s/\*/ \* /g;
                $to =~ s/\/\//\//g;
                $to =~ s/\// \/ /g;
                $to =~ s/\%/ \% /g;
                $to =~ s/\(/ \( /g;
                $to =~ s/\)/ \) /g;
                $to =~ s/ +/ /g;
                @fromList = split / /, $from;
    #from is first argument of range(). Add '$'; when need
                foreach $i (@fromList){
                    if($i =~ m/[a-z|A-Z]+/){
                        $i = "\$$i";
                    }
                }
                $from = join " ", @fromList;
                @toList = split / /, $to;
                foreach $i (@toList){
                    if($i =~ m/[a-z|A-Z]+/){
                        $i = "\$$i";
                    }elsif($i =~ m/\([a-z|A-Z]+/){
                        $i =~ s/\(/\(\$/;
                    }
                }
    #to is second argument of range().
                $to = join " ", @toList;
                if($to =~ m/(.*)?\+ ([0-9]+)/){
    #range(0,5) means foreach (0..4) in Perl so minus one
                    $ch = $1;
                    $number = $2 - 1;
                    if($number == 0){
                        $to = "$ch";
                    }else{
                        $to = "$ch + $number";
                    }
                }elsif($to =~ m/(.*)?\- ([0-9]+)/){
                    $ch = $1;
                    $number = $2 + 1;
                    $to = "$ch - $number";
                }else{
                    $to = "$to - 1";
                }
                print $spaces, "foreach $expr ($from..$to) {";
            #Handle for i in sys.stdin
            }elsif($rest =~ m/^sys\.stdin$/){
                $rest = "<STDIN>";
                print $spaces, "foreach $expr ($rest) {";
            }
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }
        }
        #Handle break continue
        if($line =~ m/(^\s*)break/){
            chomp $line;
            $line =~ s/break/last;/;
            print $line;
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }

        }if($line =~ m/(^\s*)continue/){
            chomp $line;
            $line =~ s/continue/next;/;
            print $line;
            if($comment){
                print $comment, "\n";
            }else{
                print "\n";
            }            
        }
    }
}
#If reached EOF of this python program. Check indentation and add } when needed
while(@indentation){
    $i=0;
    while($i < $indentation[0]){
        print " ";
        $i+=1;
    }
    shift @indentation;
    print "}\n";
}
