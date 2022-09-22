#!/bin/bash 

# Global checks block
[[ "$#" < 1 ]] && echo -e "Please, pass at least one project to analyze.\nIf more, separated them by a space." && exit 1
[[ ! -f "404_jenkinsfile.template" ]] && echo -e "WARNING! Not able to clean Jenkinsfile templates if Jenkinsfile has not been found" 

# Create folder if not exists
[[ -d old_templates ]] || echo -e "INFO! Creating old_templates directory for saving old Jenkinsfile templates" 


# Entry point - main
readonly my_user=CHANGEME
readonly token=CHANGEME
readonly references=old_templates

for project_name in "$@"; do

    project=$project_name
    api_url=https://bitbucket.com/rest/api/1.0/projects/$project/repos

    # Project scope checks
    # Remove files if exists
    [[ -f projects_${project}.txt ]] && rm projects_${project}.txt
    [[ -f same_logic_${project}.txt ]] && rm same_logic_${project}.txt 
    [[ -f unique_jenkins_${project}.txt ]] && rm unique_jenkins_${project}.txt 
    [[ -f not_jenkinsfiles_for_${project}.txt ]] && rm not_jenkinsfiles_for_${project}.txt 
    
    echo -e "\n### Fetching repository names for $project and cleaning them up ###\n";
    # Take name of projects dynamically
    row=0
    size=$(curl -sL -u $my_user:$token "$api_url?start=$row" | jq -r ".size")
    end=false

    while [ "$end" != "true" ];
    do
        curl -sL -u $my_user:$token "$api_url?start=$row" | jq -r ".values[].slug" >> projects_${project}.txt
        end=$(curl -sL -u $my_user:$token "$api_url?start=$row" | jq -r ".isLastPage")
        row=$(( $row + $size ))
    done


    # Take all Jenkinsfile for each repo
    for repo in $( cat projects_${project}.txt | sort ); do
        curl -u $my_user:$token $api_url/$repo/raw/Jenkinsfile -o $references/$repo-Jenkinsfile
        echo
        
        # Clean created files if there was no Jenkinsfile and remove from projects and templates to track
        diff "$references/$repo-Jenkinsfile" "404_jenkinsfile.template" &>/dev/null 
        if [[ $? == 0 ]]; then
           echo "Jenkinsfile not found for repository: $repo" >> not_jenkinsfiles_for_${project}.txt 
           rm $references/$repo-Jenkinsfile
           sed -i "/^$repo$/d" projects_${project}.txt 
           echo
        fi

    done


    ## Compares Jenkinsfile uniqueness after having cleaned project's list
    for repo in $( cat projects_${project}.txt | sort ); do
        isUnique=true
        echo -e "\n### Analyzing repository: $repo ###";
        for compared_file in $( ls $references | sort ); do
            
            # Don't compare it with itself
            [[ "${repo}-Jenkinsfile" == "$compared_file" ]] && continue
            
            # Check if there exists any diff
            diff "$references/$repo-Jenkinsfile" "$references/$compared_file" &>/dev/null 
            if [[ $? == 0 ]]; then 
                printf "%-55s | seems to have same logic than | %-55s\n" $repo $compared_file >> same_logic_${project}.txt;
                isUnique=false
                break
            fi
        done

        # Append to file that collect unique Jenkinsfile
        [[ "$isUnique" == "true" ]] && printf "%-55s | has unique logic\n" $repo >> unique_jenkins_${project}.txt

    done

done
