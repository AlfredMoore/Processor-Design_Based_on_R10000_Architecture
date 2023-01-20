#!/bin/bash 
mkdir mem_verify/final_mem
echo -e "\n"
read -r -p "Do you want to MAKE (default N) ? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Pipeline Test Begin......"
    rm mem_verify/CPI.txt
    for file in test_progs/*.s; do
        file=$(echo $file | cut -d'.' -f1)
        file1=$(echo $file | cut -d'/' -f2)

        echo "Assembling $file1"
        make assembly SOURCE=$file.s
        echo "Running $file1"
        make
        echo "Saving $file1 output"
        grep "@@@ mem" program.out > $file1+program.out
        cpi=$(grep "CPI" program.out)
        echo $file1$cpi >> mem_verify/CPI.txt
        mv $file1+program.out  ./mem_verify/final_mem/
        echo "----------$file1 Test Successfully!---------- "
    done

    for file in test_progs/*.c; do
        file=$(echo $file | cut -d'.' -f1)
        file1=$(echo $file | cut -d'/' -f2)

        echo "Assembling $file1"
        make program SOURCE=$file.s
        echo "Running $file1"
        make
        echo "Saving $file1 output"
        grep "@@@ mem" program.out > $file1+program.out
        cpi=$(grep "CPI" program.out)
        echo $file1$cpi >> mem_verify/CPI.txt
        mv $file1+program.out  ./mem_verify/final_mem/
        echo "----------$file1 Test Successfully!---------- "
    done
    
fi

# record_check=mem_verify/final_mem/haha+program.out
# if [ -f "$record_check" ]; then
#     echo "----------Mem all recorded!----------"
# else
#     echo "---------Please MAKE ASSEMBLY first----------"
# fi


# comparison
echo -e $"\n----------Compare with P3----------"
# you need firstly copy the p3 result dir "p3_mem" to the dir "mem_verify"
# "p3_mem" can be created by the p3_mem_test.sh or in xmo branch of bitbucket
cmp_path="mem_verify/p3_mem"
if [ -d $cmp_path ]
then
    rm mem_verify/final_mem/*.diff
    for file in mem_verify/final_mem/*.out; do
        file=$(echo $file | cut -d'.' -f1)
        file1=$(echo $file | cut -d'/' -f3)
        echo "Comparing $file1......"
        echo -e "\n"
        cmp1=$file.out
        cmp2=$cmp_path/$file1.out
        # echo "Comparing $cmp1 and $cmp2"
        DIFF=$(diff -q $cmp1 $cmp2)
        if [ "$DIFF" != "" ]
        then
            diff -y $cmp1 $cmp2
            diff -y $cmp1 $cmp2 > $file.diff
            echo "$file1 different saved to $file.diff"
            echo -e "\n"
            read -n 1 -s -r -p "Press any key to continue"          # delete this line to drop pressing key
            echo -e "\n"
        else
            echo "$file1 @@passed!"
        fi
    done
else
    echo "you should copy the p3_mem dir firstly, following the upper comment..."
fi

