#!/bin/sh

command="$1"
tag="$2"
main_branch="$3"
develop_branch="$4"
allow_empty_releases="$5"

check_execution_ok() {
  if [ $? -ne 0 ]
    then
      exit 1
    fi
}

echo "Executing gitflow release command=$command, tag=$tag, main_branch=$main_branch, develop_branch=$develop_branch, allow_empty_releases=$allow_empty_releases"
echo "Working directory is $(pwd)"

if [ "$command" = start ] || [ "$command" = start_finish ]; then
  git checkout -f "$main_branch"
  check_execution_ok
  git pull
  check_execution_ok
  git checkout -f -t -B "$develop_branch" origin/"$develop_branch"
  check_execution_ok

  echo "Creating branch release ..."
  git checkout -b release/"$tag"
  check_execution_ok
  echo "Branch release created!"
fi

if [ "$command" = finish ] || [ "$command" = start_finish ]; then
  commits=$(git log --no-merges --format='%H' master...release/$tag | wc -l)
  check_execution_ok
  echo "$commits commits included in the release/$tag"

  if [[ $commits > 0 || ($allow_empty_releases == "true" && $commits == 0) ]]; then
    git config user.name github-actions
    check_execution_ok
    git config user.email github-actions@github.com
    check_execution_ok
    git checkout "$main_branch"
    check_execution_ok
    git merge --no-ff release/"$tag"
    check_execution_ok
    git tag -a "$tag" -m "Release $tag"
    check_execution_ok
    git checkout "$develop_branch"
    check_execution_ok
    git merge --no-ff release/"$tag"
    check_execution_ok
    git fetch --tags origin
    check_execution_ok
    git merge "$tag"
    check_execution_ok

    echo "Pushing changes to remote ..."
    git push origin "$main_branch"
    check_execution_ok
    git push origin "$develop_branch"
    check_execution_ok
    git push origin --tags
    check_execution_ok
    echo "Changes to remote pushed!"

    echo "Deleting branch release/$tag ..."
    git checkout "$develop_branch"
    check_execution_ok
    git branch -d release/"$tag"
    check_execution_ok
    echo "Branch release/$tag deleted!"
  else
    echo "Sorry :( , you need to work more! Skipping release due to 0 commits found in release/$tag ahead $main_branch"
  fi
fi