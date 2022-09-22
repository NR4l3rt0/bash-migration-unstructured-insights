#!/bin/bash 

readonly my_user=CHANGEME
readonly token=CHANGEME
readonly references=old_templates
readonly target=model_templates
readonly project=$1
readonly scm_url=https://bitbucket.com/scm/$project

# $1 project
# $2 file with list of project's components

# Checks
[[ "$#" != 2 ]] && echo -e "ERROR! Project name and file with list of components are expected (in that order)." && exit 1
[[ $( ls | grep ^final_map* | wc -l ) > 0 ]] || echo  "ERROR! It is mandatory to have at least one 'final_map_\${project}.txt' file"
[[ -f components_not_treated.txt ]] && rm components_not_treated.txt  
[[ ! -f "$2" ]] && echo "ERROR! There is no file with name $2 in the current directory." && exit 1 

# Check that there exists base cases and create that set
total_known_projects=$( cat final_map* | sed -n '/:/p' | sed 's/ *//' | sort -u | tee set_known_projects.txt | wc -l ) 
[[ $total_known_projects == 0 ]] && echo "ERROR! There is no references to work with, please create a map first with organizer.sh" && exit 1 


# Main logic

for component in $( cat $2 ); do

   echo "### Working on $component ###\n\n"

   [[ -d $component ]] && echo "WARNING! Repository $component already exists. Skipping it!" >> components_not_treated.txt && continue

   # Check the key
   coincidence=$( grep "^$component\$" set_known_projects.txt | wc -l )
   [[ $coincidence != 1 ]] && echo "Component $component not found or is amgiguous" >> components_not_treated.txt && continue

   # Get the value
   $jenkinsfile_4x=$( grep "^$component" set_known_projects.txt | cut -d":" -f2 | sed 's/ *//' )

   # Get the target model from that value
   [[ ! -f ../$target/$jenkinsfile_4x ]] && echo "WARNING! $jenkinsfile_4x not found in $target for component $component. Skipping it!" >> components_not_treated.txt && continue  

   # GIT operations
   # clone repo
   git -c "http.extraHeader=Authorization: Bearer $token" clone $scm_url/${component}.git

   # go inside
   cd $component  

   # create branch
   git checkout -b update/up_to_ods_4x

   # select target template and do the copy inside with proper name 
   cp ../$target/$jenkinsfile_4x Jenkinsfile 

   # add and commit changes
   git add .
   git commit -m "Update Jenkinsfile to ods 4.x"

   # push to remote branch
   git -c "http.extraHeader=Authorization: Bearer $token" push origin update/up_to_ods_4x
   [[ $? == 0 ]] && echo -e "\n Changes in for $component pushed successfully\n";

   # go back and continue with the next one
   cd ..

done
