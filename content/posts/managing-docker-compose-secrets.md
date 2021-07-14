---
title: Managing Docker Compose Secrets
date: 2021-07-13T21:05:33+01:00
draft: true
tags: ["docker-compose", "secret-management"]
categories: ["docker"]
summary: Securely managing secrets is hard. Combine that with multiple container environments and you got yourself a real challenge. In this post I aim to describe how I solved secret management for my personal projects.
---

I use docker compose pretty much for everything. I remember at one point I even was maintaing a production application with docker compose. I would copy the `docker-compose.yml` file to the server and then start the containers manually.

I really liked how simple it was. There was nothing to maintain apart from the same docker compose file I used locally during development! Managing secrets was annoying though. Not impossible, but mighty annoying.

Over the years I've tried multiple approaches - I've tried creating `.env` file, I've tried writing a shell script, I've templated the `docker-compose.yml`, I've even hard coded secrets in `docker-compose.yml` (don't do that). None of the approaches truly made me think "yeah, this is nice". It was more like "hope no one sees this xoxo".

## The double dash mystery

One day I was messing arround with SSH host autocomplete and I came accross the peculiar looking double dash (`--`) syntax:

```shell
compgen -W "$WORD_LIST" -- ${CURRENT_WORD}
```

Turns out the double dash is used by most shells as a delimiter indicating the end of the options after which only positional arguments are accepted.

That got me thinking. What if I could write a program that would read the secrets from _somewhere_ and then expose them to docker compose as environment variables?

I've played with this idea before with a shell script, but quickly abandoned it because the secrets still had to be stored _somewhere_ safely. This time around I was inspired by [ansible-vault](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html)! I could store the secrets in an encrypted file right there along other files in the git repo!

## Docker compose and environment variables

I already knew (\*cough\* from previous experience \*cough\*) that docker compose offers many ways to pass environment variables to containers. One approach immediately spring to mind - I could pass them through the `environment` key in the `docker-compose.yml`:

```yaml
environment:
  - ENV=development
  - TAG=${GIT_COMMIT}
  - SECRET_KEY
```

Please note the last item in the array (`SECRET_KEY`). This tells docker compose to resolve the environment variable on the machine on which the compose is running on. Yes! We're on to something here!

## Vaults for storing secrets

After a couple of days when I finally "understood" how to use cryptographic functions in Go, I've managed to conjure [env-vault](https://github.com/romantomjak/env-vault)! A convenient way to launch a program with environment variables populated from an encrypted file.

Once you've got `env-vault` installed, you can create a Vault using the `create` sub-command. Let's create a vault named `prod.env` to hold our production secrets:

```shell
env-vault create prod.env
```

Running the command above will prompt for a new password and then open your favorite `$EDITOR` to input the environment variables. Let's add the `SECRET_KEY` secret now:

```shell
SECRET_KEY=somesecretformyproject
```

Save the file and close your editor. `env-vault` will encrypt the plain text using AES256-GCM symmetrical encryption. Vaults are safe to commit even on public repos, but like with everything else you must decide for yourself if you're willing to accept the risk.

## Telling docker compose about the secrets

Now that we have a Vault, let's see how we can use `env-vault` to decrypt secrets and expose them as environment variables to other programs. The general form for starting other programs looks like this:

```shell
env-vault <vault> <program> -- <program-arg1> <program-arg2> <...>
```

The `<program>` argument is the executable that will be launched with environment variables from the encrypted file pointed to by `<vault>` argument. Everything after the double dashes (`--`) will be collected by `env-vault` and passed to the `<program>`.

Here is how we can use this to tell docker compose about the secrets:

```shell
env-vault prod.env docker-compose -- up -d
```

It looks somewhat mad, but essentially `env-vault` will decrypt `prod.env` and expose found environment variables to docker compose. That's all you need to know to begin using `env-vault`!

## Managing Vault passwords

You will need to develop a strategy for managing your vault passwords. Each time you decrypt a Vault, you must provide a password. You can use a single password for everything or you can use multiple passwords for different environments and projects. However, you will then need to keep track of your Vault passwords.

If you go down the route of using a one password for all your Vaults, you can set the `ENV_VAULT_PASSWORD` environment variable. When it is set, `env-vault` will use it to decrypt vaults automatically and you won't get prompted for a password any time you interact with a Vault. You can set it like so:

```shell
export ENV_VAULT_PASSWORD=somepassword
```

## Adding a Makefile to speed things up

Makefiles are at the center of all my workflows and it is how I interact with docker compose and various other tools. If you've set the `ENV_VAULT_PASSWORD` environment variable you will forget the `env-vault` is even there!

Here is an example Makefile target for decrypting secrets and starting containers:

```make
up: ## Start all containers in detached mode
	env-vault prod.env docker-compose -- -f docker-compose.yml up -d
```

so now you can run:

```shell
make up
```

and `env-vault` will take it from there. Yeah, this is nice.

## Conclusion

Simplicity is paramount when I'm not working on a project all the time, but only every now and then (\*cough\* like with all of my side projects \*cough\*). The less there is to remember the faster I can jump right back into it!

Security is important, but so is simplicity. `env-vault` reduces the risk of unintentionally commiting secrets to a public repo and offers a convenient way to manage them.