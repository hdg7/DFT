#!/bin/bash

#Remember to set up the DFT home variable as:
#export DFT_HOME=/path/to/DFT

FILE=$1
MAP=$2
ROOTDIR=$3
INPUTS=$4


cd $ROOTDIR
NAME=$(basename $FILE | cut -f1 -d'.')
FUNC=$(cat $MAP | grep $NAME | cut -f2 -d';')
mkdir $NAME
cp $FILE $NAME/
cd $NAME
NAME=$(basename $FILE)
echo "
signed int child_pid =-1 ;
int inst_flag=0;
void kill_child(int sig)
{
    kill(child_pid,9);
}" > $NAME.header

python3 $DFT_HOME/frontend/preprocessing/preproGeneral.py $NAME $FUNC

for INSTRUMENTED in `ls $NAME.L*.cbmc.c`
do
    
    TESTFILE=$(echo "$(echo $INSTRUMENTED | rev | cut -f3- -d'.' | rev).test.c")
    LINE=$(echo "$(echo $INSTRUMENTED | rev | cut -f3 -d'.' | rev).test.c")
    timeout 10 cbmc $INSTRUMENTED --unwind 5 --function $FUNC --z3 --outfile $INSTRUMENTED.z3
    if [ -s $INSTRUMENTED.z3 ]
    then
	rm *cov.c
	cat $INSTRUMENTED.z3 | sed -n '/(check-sat)/q;p' | sed 's/^;.*//g' | tr ':!@;!#&' '_______' | tail -n +5 > $INSTRUMENTED.clean.z3
	#python3 $DFT_HOME/frontend/execution/dft.Rand.py $TESTFILE mainFake  $INSTRUMENTED.clean.z3 $INPUTS
	timeout 120 python3 $DFT_HOME/frontend/generation/gen.py randPareto $INSTRUMENTED $TESTFILE $FUNC $INPUTS $INSTRUMENTED.clean.z3
	python3 $DFT_HOME/frontend/execution/set.inputs.py sem $TESTFILE $FUNC $INSTRUMENTED.inputs $INPUTS $RANDOM  
	cat $NAME.header $TESTFILE.cov.c | grep -v  "void \*\*__builtin_va_list" > finalTest.$LINE.c
	gcc -fprofile-arcs -ftest-coverage -lm finalTest.$LINE.c
	./a.out 2>&1 >/dev/null | sed 's/]]/ /g' | tr ' ' '\n' | grep REACHED | wc -l > count.$LINE.txt
	#    ./a.out
	gcov -fb finalTest.$LINE.c > coverage.$LINE.txt
    fi
done

