#What?
This script is kind of like a task-runner. Really it could be used for far more general things than ITG. I might put it on my personal github without the ITG stuff attached.

#How
The idea is:

- Configure your services/tasks in menu.json
- Start a minimal X server (I use a SysV init script to start Xorg)
- Launch a terminal application (I usr urxvt) that runs the menu.sh script

The main reason to do it this way is for weird arcade displays. I need xorg to start to get a 15kHz signal out.

#Gotchas
Each task or whatever can be run as a user specified in menu.json. You'll probably need to add those users to xauth or they won't be able to talk to the X server:

```
xhost + SI:localuser:someLocalUserHere
```

