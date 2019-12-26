#!/bin/bash

#Remember to set up the DFT home variable as:
#export DFT_HOME=/path/to/DFT

FILE=$1
FUNC=$2
ROOTDIR=$3
INPUTS=$4

cd $ROOTDIR
NAME=$(basename $FILE | cut -f1 -d'.')
mkdir $NAME
cp $FILE $NAME/
cd $NAME
NAME=$(basename $FILE)
cat $NAME | grep "#include" > $NAME.header
echo "#include <signal.h>
#include<stdlib.h>
#include<stdio.h>
#include<errno.h>
#include <unistd.h>
#include <sys/wait.h>
pid_t child_pid =-1 ;
int inst_flag=0;
void kill_child(int sig)
{
    kill(child_pid,SIGKILL);
}" >> $NAME.header
cat $NAME | grep -v "#include" > $NAME.1.c
gcc -E $NAME.1.c > $NAME.pre.c
python3 $DFT_HOME/frontend/preprocessing/preproGeneral.py $NAME.pre.c $FUNC

for INSTRUMENTED in `ls $NAME.pre.c.pre.c.L*.cbmc.c`
do
    
    TESTFILE=$(echo "$(echo $INSTRUMENTED | rev | cut -f3- -d'.' | rev).test.c")
    LINE=$(echo "$(echo $INSTRUMENTED | rev | cut -f3 -d'.' | rev).test.c")
    timeout 10 cbmc $INSTRUMENTED --unwind 5 --function mainFake --z3 --outfile $INSTRUMENTED.z3
    if [ -s $INSTRUMENTED.z3 ]
    then
	rm *cov.c
	cat $INSTRUMENTED.z3 | sed -n '/(check-sat)/q;p' | sed 's/^;.*//g' | tr ':!@;!#&' '_______' | tail -n +5 > $INSTRUMENTED.clean.z3
#	python3 $DFT_HOME/frontend/execution/dft.SPEA2.py $TESTFILE mainFake  $INSTRUMENTED.clean.z3 $INPUTS
	python3 $DFT_HOME/frontend/generation/dft.SPEA2.py $TESTFILE $TESTFILE  $INSTRUMENTED.clean.z3 mainFake $INPUTS
	mv pareto pareto.$LINE
	cat $NAME.header $TESTFILE.cov.c > finalTest.$LINE.c
	gcc -fprofile-arcs -ftest-coverage -lm finalTest.$LINE.c
	./a.out 2>&1 >/dev/null | sed 's/]]/ /g' | tr ' ' '\n' | grep REACHED | wc -l > count.$LINE.txt
	#    ./a.out
	gcov -fb finalTest.$LINE.c > coverage.$LINE.txt
    fi
done

