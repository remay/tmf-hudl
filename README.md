# TMF Custom ROM for Hudl 1
On June 26th, 2020, the certificate that backs connections to
https://device.mobile.tesco.com/ expired.   This causes all Tesco provided
updates for Hudl 1 to fail to be served from this back end.   On factory re-set
the Hudl 1 setup wizard requires an update check to this back-end to complete
successfully ... as this check fails, the wizard blocks, requesting the user to
check their internet connection.  There is no (easy) way out of this.

There is a way that works at the time of writing to jump out of the wizard and
set the device's time into the past (documented [here](https://rob.themayfamily.me.uk/hudl)),
but this may not continue to work in the
future, and needs to be repeated on every factory reset of the device.

This repo hosts the information and tools to build and flash a custom ROM
(firmware) for a Hudl 1 device that elimminate this problem, as well as removing
some of the Tesco customisations.

For more details please read:

- If all you want is to download and install the TMF Custom ROM, then head to the
[Wiki](https://github.com/remay/tmf-hudl/wiki) and find eveything you
need there.
- [Tools and environment for building](https://github.com/remay/tmf-hudl/wiki/Tools-and-Environment-for-building-TMF-Custom-ROM)

# Credits

Thanks to everyone at [XDA](https://forum.xda-developers.com/) and [FreakTab](https://forum.freaktab.com/) whose past work enabled me to pull all this together.
If I understand correctly the modified SystemUI.apk was originally created by [Paul O'Brien](https://twitter.com/paulobrien) (of [MoDaCo](https://modaco.com/) fame).  Thank you to him for that.

