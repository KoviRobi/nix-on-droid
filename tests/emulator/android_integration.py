import time

import bootstrap_channels

from common import screenshot, wait_for


def run(d):
    nod = bootstrap_channels.run(d)

    # Verify that android-integration tools aren't installed by default
    d('input text "am"')
    d.ui.press('enter')
    wait_for(d, 'bash: am: command not found')
    screenshot(d, 'no-am')
    d('input text "termux-setup-storage"')
    d.ui.press('enter')
    wait_for(d, 'bash: termux-setup-storage: command not found')
    screenshot(d, 'no-termux-setup-storage')

    # Apply a config that enables android-integration tools
    cfg = ('/data/local/tmp/n-o-d/unpacked/tests/on-device/'
           'config-android-integration.nix')
    d(f'input text \'cp {cfg} .config/nixpkgs/nix-on-droid.nix\'')
    d.ui.press('enter')
    screenshot(d, 'pre-switch')
    d('input text "nix-on-droid switch && echo integration  tools  installed"')
    d.ui.press('enter')
    wait_for(d, 'integration tools installed')
    screenshot(d, 'post-switch')

    # Verify am is there
    d('input text "am | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'termux-am is a wrapper script')
    screenshot(d, 'am-appears')

    # Smoke-test that am doesn't work yet
    d('input text "am start -a android.settings.SETTINGS 2>&1 | head -n5"')
    d.ui.press('enter')
    screenshot(d, 'am-invoked for the first time')
    wait_for(d, 'Nix requires "Display over other apps" permission')
    wait_for(d, 'https://dontkillmyapp.com')
    screenshot(d, 'am-wants-permission')

    # ... there might be a notification now, get rid of it
    time.sleep(3)
    screenshot(d, 'am-wants-permission-3-seconds-later')
    if 'text="TermuxAm Socket Server Error"' in d.ui.dump_hierarchy():
        d.ui.open_notification()
        time.sleep(1)
        screenshot(d, 'notification-opened')
        d.ui(text='TermuxAm Socket Server Error').swipe('right')
        screenshot(d, 'error-notification-swiped-right')
        d.ui.press('back')
        screenshot(d, 'back')

    # Grant nix app 'Draw over other apps' permission
    nod.permissions += 'android.permission.SYSTEM_ALERT_WINDOW'

    # Smoke-test that am works
    d('input text "am start -a android.settings.SETTINGS"')
    d.ui.press('enter')
    screenshot(d, 'settings-opening')
    wait_for(d, 'Search settings')
    wait_for(d, 'Network')
    screenshot(d, 'settings-awaited')
    d.ui.press('back')
    screenshot(d, 'back-from-settings')

    # Verify we're back
    d('input text "am | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'termux-am is a wrapper script')

    # Verify termux-setup-storage is there
    d('input text "termux-setup-storage"')
    d.ui.press('enter')
    screenshot(d, 'termux-setup-storage-invoked')
    wait_for(d, 'Allow Nix to access')
    screenshot(d, 'permission-requested')
    if 'text="Allow"' in d.ui.dump_hierarchy():
        d.ui(text='Allow').click()
    elif 'text="ALLOW"' in d.ui.dump_hierarchy():
        d.ui(text='ALLOW').click()
    screenshot(d, 'permission-granted')

    d('input text "ls -l storage"')
    d.ui.press('enter')
    screenshot(d, 'storage-listed')
    wait_for(d, 'pictures -&gt; /storage/emulated/0/Pictures')
    wait_for(d, 'shared -&gt; /storage/emulated/0')
    screenshot(d, 'storage-listed-ok')

    # Invoke termux-setup-storage again
    d('input text "termux-setup-storage"')
    d.ui.press('enter')
    screenshot(d, 'termux-setup-storage-invoked-again')
    wait_for(d, 'already exists')
    wait_for(d, 'Do you want to continue?')
    d.ui.press('enter')
    wait_for(d, 'Aborting configuration and leaving')
