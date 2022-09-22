#!/bin/bash 

[[ "$#" == 0 ]] && echo -e "Please, pass project name/-s spaced separated." && exit 1

[[ -f total_final_map.txt ]] && echo "Cleaning total_final_map.txt file" && rm total_final_map.txt

for project_name in "$@"; do
    
    project=$project_name
    api_url=https://bitbucket.com/rest/api/1.0/projects/$project/repos

    # Cannot continue if these files don't exist 
    [[ ! -f projects_${project}.txt ]] && echo "Please, provide a projects_${project}.txt file" && exit 1 
    [[ $(ls same* | wc -l ) == 0 ]] && echo "Please, provide some same_logic.txt file." && exit 1 
    [[ $(ls unique* | wc -l ) == 0 ]] && echo "Please, provide some unique_jenkins.txt file." && exit 1 


    # Remove final map file for creating new metrics
    [[ -f final_map_${project}.txt ]] && echo "Cleaning final_map_${project}.txt file" && rm final_map_${project}.txt

    # Associative array
    declare -A myDict

    # Mapping old template with target one
    for component in $( cat projects_${project}.txt | sort ); do
        # If this component is being targeted more than once, then it is going to be treated as target model for others and itself
        repetitions=$( cat same* | grep "${component}-Jenkinsfile" | wc -l ) 
        # one to many means it is going to be mapped to itself
        if [[ $repetitions > 1 ]]; then
            myDict[$component]=$component 
            echo "$component : ${myDict[$component]}" >> final_map_${project}.txt
            continue
        fi

        # one to one means it should check what it points to 
        repetitions=$( cat same* | grep "^$component " | cut -d":" -f3 | uniq | wc -l ) 
        if [[ $repetitions == 1 ]]; then
            myDict[$component]=$( cat same* | grep "^$component " | cut -d"|" -f3 | sed 's/ *//' | sed 's/-Jenkinsfile//' )
            echo "$component : ${myDict[$component]}" >> final_map_${project}.txt

        else
            # one to one (itself) but in unique's file (zero repetition)
            isThere=$( cat unique* | grep "$component " | cut -d":" -f1 | uniq | wc -l )
            if [[ $isThere == 1 ]]; then
                myDict[$component]=$component 
                echo "$component : ${myDict[$component]}" >> final_map_${project}.txt
            else
                printf "\n\tWARNING! Target file not found for component %s. Or perhaps there is a duplicate. Skipping it!\n\n" $component | tee -a warnings.txt
            fi
        fi

    done

    # Calculate total of distincts references per project
    total_refs=$( cat final_map_${project}.txt | cut -d":" -f2 | sed 's/ *//' | sort -u | wc -l ) 
    echo -e "\nThere are $total_refs references in project $project.\n" | tee -a final_map_${project}.txt

# Debug purpose
#    for el in ${!myDict[@]}; do
#            echo "Key: $el => Value: ${myDict[$el]}"
#    done
 
    unset myDict total_refs
    
done

# Calculate total of distincts references globally
total_refs=$( cat final_map* | sed -n '/:/p' | cut -d":" -f2 | sed 's/ *//' |  sort -u | wc -l ) 
echo -e "\nThere are $total_refs distinct references in total.\n" | tee -a total_final_map.txt
