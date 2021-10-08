#!/bin/bash

# lines should look like this: (relevant fields are highlighted)
#
# prefix_sufix - string with non relevant info: 0.00s
# ^^^^^^^^^^^^ <- category_subcategory          ^^^^^ <- time
#
# Example:
# gcc_O2 - Time taken by my implementation: 0.42s
# category: gcc  subcategory: O2  time: 0.42s

declare -A array
categories=""
subcategories=""

re=

while read line
do
    time=${line##*: }
    time=${time%%s}
    label=${line%% -*}
    category=${label%%_*}
    subcategory=${label##*_}

    # Skip lines with no time results
    if ! [[ $time =~ ^[0-9]+\.?[0-9]*$ ]]; then
        continue
    fi

    array[$label]="${array[$label]}${array[$label]:+ }$time"
    categories="$categories $category"
    subcategories="$subcategories $subcategory"
done

# Sort each list of times in array (first column will have lowest time)

for key in "${!array[@]}"; do
    array[$key]=`echo "${array[$key]}" | tr ' ' '\n' | sort | tr '\n' ' '`
done

# Sort lists of categories/subcategories and get rid of dupes
categories=`echo $categories | tr ' ' '\n' | sort | uniq | tr '\n' ' '`
subcategories=`echo $subcategories | tr ' ' '\n' | sort | uniq | tr '\n' ' '`

# for key in "${!array[@]}"; do
#     category=${key%%_*}
#     subcategory=${key##*_}
#     echo "$key->${array[$key]}";
# done

echo "Categories: $categories"
for subcat in $subcategories; do
    printf "%8s: " $subcat
    for cat in $categories; do
        printf "%08.2f " ${array[${cat}_${subcat}]}; echo -ne "   "
    done
    echo
done
