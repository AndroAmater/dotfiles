# Compositor
Use Compton (https://github.com/chjj/compton) as the compositor. Compton docs say to prefer nvidia vsync. See how to enable it below.

# Nvidia Vsync fix

>> https://www.makeuseof.com/fix-screen-tearing-on-linux/#:~:text=To%20fix%20screen%20tearing%20with,and%20restart%20your%20Linux%20desktop

To enable vsync follow the guide above:
- To fix screen tearing with NVIDIA cards, simply fire up the NVIDIA X Server Settings software. In it, navigate to X Server Display Configuration > Advanced.
- There you will find an unchecked option: Force Full Composition Pipeline. Enable it and restart your Linux desktop.
- Additionally, you might want to create an auto-start application with the command:
```bash
nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
```

# Andrej-server X11 config
```bash
cp nvidia/xorg.conf /etc/X11/xorg.conf
```
