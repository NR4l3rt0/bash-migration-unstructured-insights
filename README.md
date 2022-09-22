### analyzer.sh do the following things:

- Takes name of projects dynamically (passed as parameters, minimum 1)
- Takes all Jenkinsfile for each repo's project
- Clean projects that do not have Jenkinsfile
- Compares Jenkinsfile for uniqueness
- Fill old_templates with all references
- Document all in separate .txt files

### organizer.sh do the following things:

- Takes name of projects dynamically (passed as parameters, minimum 1)
- Creates a map between each component and its associate target solution (model)
- Gives feedback about how many components should be considered (the greater number of old_templates, the better it is generating meaningful connections) 
- Document all in .txt files

### commiter.sh do the following things:

- Takes the name of a single project and a list of components (passed as a file and over which an iteration will be made)
- After sanitizing different use cases, does the git logic for pushing changes in a new branch.
- Document all in .txt files

Note: it will not trigger a new build unless the Jenkinsfile's branch-mapping has a default '*' value or it is triggered by 'update/*'

### Requirements:
- Bash > v4.0
- Curl
- jq


## Direction:
It is considered for creating meaning in the long term. That is, the folder old_templates and model_templates can be saved in a document database and take advantage of the unstructured data for creating predictions and insights.
