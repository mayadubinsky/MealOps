# Contributing to MealOps

## Workflow

Each change should be connected to a Jira task.

1. Update the local `main` branch.
2. Create a branch for the Jira task.
3. Make and test the changes.
4. Commit changes using the Jira key.
5. Push the branch to GitHub.
6. Open a pull request.
7. Merge the pull request into `main`.
8. Delete the completed branch.

## Branch naming

Use the Jira key followed by a short lowercase description:
KAN-<task number>-<task name>
For example:
KAN-12-high-level-architecture

## Commit messages

Start each commit with the Jira key:
KAN-<task number><explain changes>
For example:
KAN-12 add initial architecture document

## Pull requests

Use the Jira key in the title:
KAN-<task number><task description>
KAN-12: Create high-level architecture

The pull-request description should explain:

- What changed
- Why it changed
- How it was verified
- The related Jira task

## Main branch

Routine work should not be committed directly to `main`. Each Jira task should use a separate branch and pull request.
