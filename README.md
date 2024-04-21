# this project moved to https://github.com/balamod/balamod

Sorry if I'm not really active right now, it's a bit complex and I feel like it's slowing down the project.

To address this issue, I've decided to move balamod over to https://github.com/balamod/balamod in order to keep the project alive, and not be a bottleneck. I will also fork that repository into `UwUDev/balamod` to keep the mod menu working without having to patch balamod. Existing contributors to balamod will be invited to the balamod github organization in order to keep maintaining the project.

I originally made this project, not just to have a popular repository on github, but mostly to make modding more accessible for balatro. This migration is necessary, even if it causes bugs along the way.

I'm very sorry for the PRs that were on hold while I was inactive, and current PRs on UwUDev/balamod will need to be made again on balamod/balamod due to this migration. 

For contributors, you can easily migrate to the balamod repo from your forks by running these commands :

```
$ git remote set-url upstream git@github.com:balamod/balamod.git
$ git pull upstream master --no-rebase --force
```

For long time contributors, you will also be able to push branches directly to balamod/balamod, but will still need to make pull requests to merge onto master, as this branch will be protected going forwards.

Thank you to all of the contributors, stargazers and community members!
