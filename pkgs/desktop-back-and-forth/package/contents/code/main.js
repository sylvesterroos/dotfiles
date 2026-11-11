let previousDesktop = null;

workspace.currentDesktopChanged.connect(previous => {
    previousDesktop = previous;
});

function switchToPreviousDesktop() {
    if (previousDesktop) {
        workspace.currentDesktop = previousDesktop;
    }
}

registerShortcut("Switch to Previously Used Desktop", "Switch to Previously Used Desktop", "", switchToPreviousDesktop);

workspace.desktops.forEach((desktop, index) => {
    const number = index + 1;
    registerShortcut(`Back and Forth Desktop ${number}`, `Back and Forth Desktop ${number}`, "", () => {
        if (workspace.currentDesktop === desktop) {
            switchToPreviousDesktop();
        } else {
            workspace.currentDesktop = desktop;
        }
    });
});
