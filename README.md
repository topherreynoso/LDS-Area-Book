LDS Area Book
=========

A way for ward leaders to track and manage their efforts to care for the ward.

The ward area book is a web application, allowing Ward Council members the ability to access it from pretty much any internet-enabled device at any time.

This is the code that [ldsareabook.org](http://www.ldsareabook.org) runs on. Feel free to set up an area book for your ward there or, alternatively, fork this project and run an area book website of your own if you feel confident in ruby on rails (please visit the wiki for more details on this option and the required notices and disclaimers that you must post if you do so).

You can also follow a discussion of this app over at [Tech LDS](https://tech.lds.org/forum/viewtopic.php?f=32&t=17149).

Here are some facts and features:

1. Anyone can create an account and a ward area book for their unit.
2. The ward area book tracks visits and attempts to contact members of the ward. This is meant to facilitate communication between the Ward Council in order to allow them to focus on the needs and well-being of individuals and families in the ward.
3. The ward area book also tracks visits and attempts to contact investigators as a way to assist the Ward Mission Leader and Full-Time Missionaries in reporting on the progress of investigators and make the Ward Council aware of needed assistance.
4. Each area book has limited access. First, before any one has access to your area book you must accept their request to view it. Individuals can only be members of one area book at a time.
5. All member information is encrypted. In addition to approving individuals for access, each area book has a password that must be set and that only area book administrators can change as needed. This password is necessary in order to decrypt any information in the area book. This password is never stored on the server database so even someone who has server access cannot view any member information without the decryption password you have chosen.
6. Since ward passwords are not stored anywhere in the server database, if you lose it, your data is gone forever. So be sure to store this some place safe.
7. By tracking the Ward Council's outreach efforts, a nice story is generated over time for each family. That way, as leadership changes, data is not lost but easily passed on to the next responsible party.
8. This service is completely free and always will be.
