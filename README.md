# tmf-hudl
On June 26th, 2020, the certificate that backs connections to
https://device.mobile.tesco.com/ expired.   This causes all Tesco provided
updates for Hudl 1 to fail to be served from this back end.   On factory re-set
the Hudl 1 setup wizard requires an update check to this back-end to complete
successfully ... as this check fails, the wizard blocks, requesting the user to
check their internet connection.  There is no (easy) way out of this.

There is a way that works at the time of writing to jump out of the wizard and
set the device's time into the past (documented here:
https://rob.themayfamily.me.uk/hudl), but this may not continue to work in the
future, and needs to be repeated on every factory reset of the device.

This repo hosts the information and tools to build and flash a custom ROM
(firmware) for a Hudl 1 device that elimminate this problem, as well as removing
some of the Tesco customisations.

For more details please read:
- 01-README
- 02-TOOLS
- 03-BUILD
- 04-INSTALL
- 05-TODO

If all you want is to download and install the TMF Custom ROM, then head to the
releases https://github.com/remay/tmf-hudl/releases page and find eveything you
need there.
