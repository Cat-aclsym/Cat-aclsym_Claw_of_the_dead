# Cat'aclsym : Claw of the dead

A Tower Defense game in zombie apocalypse theme. You play with cats, and you have to defend your city from the zombie invasion using towers.

# Requirements :

	- Godot 4.2

## GitHub

#### Commit :

- Commit messages are in English, in the present tense, must be short and concise.

**type(scope): subject<br><br>closes**

* **type**: type of commit
* **scope**: the scope that is affected by this commit 1 to 2 word, can contain space
* **subject**: a short description of the commit, around 20 words max, can contain capitalization or not
* **closes**: a list of issues closed by this commit, in the `Close #42` format, separated by a comma and a space

#### Types :

* `ci` : Change of files and scripts related to continuous integration
* `chore` : Change of the build system or development tools
* `feat` : New feature
* `fix` : Bug fix
* `perf` : Optimization of the code to improve performance
* `refactor` : Modification of the code without changing functionality
* `style` : Change to the code style
* `tweak` : Small change to the code that doesn't change the functionality

Commit regexp:

```regexp
(chore|docs|feat|fix|perf|refactor|style|tweak)(\(.*\)): [A-Z].*\.(\s+Closes #\d+(, closes #\d+)*)?
```

#### Examples :

```
feat(zombies): Add new pigeon zombie.
```

```
fix(tower gui): fix tower name not being displayed correctly
```

```
tweak(animations): Change zombie animation speed.
```

```
feat(ingredients): Add new ingredient.

Closes #42
```

### Branches :

We are following the [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).

#### Branch naming :

- Branch names are in English, brief and concise, in lowercase, and must be separated by a hyphen (`-`).
- Branch names must start with the type of branch, followed by a slash (`/`), followed by the subject of the branch.

#### Types :

* `feature` : New feature
* `fix` : Bug fix
* `hotfix` : Critical bug fix
* `release` : Release

#### Examples :

```
feature/big-zombie
```

```
fix/fix-tower-gui
```

### Issues

Issues are used to track bugs, enhancements, or other requests.
Each commit must be linked to an issue.

#### Issue naming :

- Issue names are in English, short and concise, must be a phrase, and must be capitalized.
- References to classes/functions/variables must be in backticks (\`).
- References to files must be in backticks (\`) and in italic (\*).
- A description of the issue should be added when the title is not enough and details are needed.
- References to other issues are in the `#42` format.

#### Examples :

```
Add new `Zombie` class.
```

```
Fix `TowerGui` not displaying tower name correctly.
```

### Pull requests :

- Pull requests follow the same rules as issues.
- Each pull request must be linked to an issue.
- A pull request can contain multiple commits.
- A pull request can be merged only if it has been approved by at least one reviewer.
