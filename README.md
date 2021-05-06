# Linter

Drone/Woodpecker CI "plugin"  

```yaml
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
    before_script: |
      touch /tmp/foo
      if [[ -f /tmp/foo ]]; then
        echo "foo"
      fi
    ignore:
      - SC1234
      - SC5678
    path:
      - ./build/scripts
    files:
      - ./foo/script1.sh
      - ./foo/script2.sh
      - ./bar/run-*
      - check.sh
```
---
List of linters **to be installed**
* [PHP-CS-Fixer](https://github.com/FriendsOfPHP/PHP-CS-Fixer)

## Linters & basic usage
| Name           | Plug-in  | Description                                                                  | Link                                              |
|:--------------:|:--------:|:----------------------------------------------------------------------------:|:--------------------------------------------------|
| **shellcheck** | `shell`  | A shell script static analysis tool                                          | [GitHub](https://github.com/koalaman/shellcheck)  |
| **yamllint**   | `yaml`   | A linter for YAML files                                                      | [GitHub](https://github.com/adrienverge/yamllint) |
| **hadolint**   | `docker` | A smarter Dockerfile linter that helps you build best practice Docker images | [GitHub](https://github.com/hadolint/hadolint)    |
#### Enabling linter
<details>
  <summary><b>Shell</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
+   lint: shell
```
</details>
  
<details>
  <summary><b>YAML</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
+   lint: yaml
```
</details>
  
<details>
  <summary><b>Docker</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
+   lint: docker
```
</details>
  

## Examples
#### Common pipeline options
| Option            | Accepted values                        | Mandatory | Description                                                                               |
|:-----------------:|:---------------------------------------|:---------:|:------------------------------------------------------------------------------------------|
| **debug**         | Any kind of value                      | *NO*      | If set, **enables debug** mode (`set -o xtrace`) for wrapper and subscripts               |
| **errexit**       | Any kind of value                      | *NO*      | If set, **enables exit-on-error** mode (`set -o errexit`) for wrapper and subcripts       |
| **path**          | YAML list of strings                   | *NO*      | Specifies custom search path.<br/>If not set linter will attempt to search for `*.sh` scripts starting from current directory** |
| **files**         | YAML list of strings                   | *NO*      | Specifies custom scripts to be checked                                                    |
| **before_script** | YAML-formatted inline strings or lists | *NO*      | If you need to run something *before* step execution, this is a right place to add those things |
| **ignore**        | YAML list of strings                   | *NO*      | List of linter codes to ignore                                                            |

<details>
  <summary><b>Files</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   files:
+     - ./foo/script1.sh
+     - ./foo/script2.sh
+     - ./bar/run-*
+     - check.sh
```
</details>
  
<details>
  <summary><b>Path</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   path:
+     - ./foo
+     - ./build/scripts
```
</details>
  
<details>
  <summary><b>Path & files</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   path:
+     - ./build/scripts
+   files:
+     - ./foo/script1.sh
+     - ./foo/script2.sh
+     - ./bar/run-*
+     - check.sh
```
</details>
  
<details>
  <summary><b>Pre-run inline script</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   before_script: |
+     touch /tmp/foo
+     if [[ -f /tmp/foo ]]; then
+       echo "foo"
+     fi
```
</details>
  
<details>
  <summary><b>Pre-run line-by-line script</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   before_script:
+     - touch /tmp/bar
+     - "[[ -f /tmp/bar ]] && echo bar"
```
</details>
  
<details>
  <summary><b>Ignore</b> (click to expand)</summary>
  
```diff
pipeline:
  lint:
    image: sevoid/linter:plugin
    lint: shell
+   ignore:
+     - SC1234
+     - SC5678
```
</details>
  
<details>
  <summary><b>Enable debug and/or errexit</b> (click to expand)</summary>
  
#### debug
```diff
pipeline:
  lint-shell:
    image: sevoid/linter:plugin
    lint: shell
+   debug: true
```
#### errexit
```diff
pipeline:
  lint-shell:
    image: sevoid/linter:plugin
    lint: shell
+   errexit: true
```
#### Enable debug and errexit
```diff
pipeline:
  lint-shell:
    image: sevoid/linter:plugin
    lint: shell
+   debug: true
+   errexit: true
```
</details>
  

## Shell linter
### Configuration file
Default behaviour of `shellcheck` can be overriden by placing `.shellcheckrc` into root directory of your git repo.
<details>
  <summary>Example of <b>.shellcheckrc</b> (click to expand)</summary>
  
```
color=always
severity=error
disable=SC1234
disable=SC5678
```
</details>
  
### Pipeline options
| Option       | Accepted values                                                            | Default value | Mandatory | Description                                                            |
|:------------:|:---------------------------------------------------------------------------|:-------------:|:---------:|:-----------------------------------------------------------------------|
| **lint**     | <ul><li>`sh`</li><li>`shell`</li><li>`bash`</li></ul>                      |               | **YES**   | Specifies type of linter to be used                                     |
| **color**    | <ul><li>`auto`</li><li>`always`</li></ul>                                  | `always`      | *NO*      | **Linter option**<br/>Enables/disables colourful output                |
| **severity** | <ul><li>`error`</li><li>`warning`</li><li>`info`</li><li>`style`</li></ul> | `style`       | *NO*      | **Linter option**<br/>Specifies minimum severity of errors to consider |

## YAML linter
### Configuration file
Default behaviour of `yamllint` can be overriden by placing config file into root directory of your git repo.  
Configuration file names:
* `.yamllint`
* `.yamllint.yml`
* `.yamllint.yaml`
<details>
  <summary>Example of <b>.yamllint</b> (click to expand)</summary>
  
```yaml
yaml-files:
  - '*.yaml'
  - '*.yml'
  - '.yamllint'
locale: en_US.UTF-8
extends: default
rules:
  # 80 chars should be enough, but don't fail if a line is longer
  line-length:
    max: 80
    level: warning
```
</details>
  
### Pipeline options
| Option       | Accepted values                        | Default value | Mandatory | Description                         |
|:------------:|:---------------------------------------|:-------------:|:---------:|:------------------------------------|
| **lint**     | <ul><li>`yml`</li><li>`yaml`</li></ul> |               | **YES**   | Specifies type of linter to be used |

