HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree
=================================================

This software is an autoregressive HMM version of the [HTS demo][hts_demo],
which is designed to demonstrate the capabilities of [HTS][hts] for statistical
speech synthesis.
Specifically, it is adapted from the STRAIGHT version of the English speaker
dependent training demo for HTS 2.1 (for HTK 3.4).
It requires a version of HTS 2.1 with the
[Autoregressive HMM for HTS](http://mi.eng.cam.ac.uk/research/emime/ar-for-hts/)
patch applied.
This patch adds support for the autoregressive HMM, including autoregressive
clustering, to HTS.


Set-up
------

[HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree](https://github.com/MattShannon/HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree) is hosted on github.
To obtain the latest source code using git:

    git clone git://github.com/MattShannon/HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.git

To set-up this directory, please follow the instructions in `INSTALL`.


License
-------
Please see the file `License` for details of the license and warranty for HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.


Bugs
----

Please use the
[issue tracker](https://github.com/MattShannon/HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree/issues)
to submit bug reports.


Contact
-------

The original author of the HTS demo is the HTS working group.
The HTS users mailing list is at <hts-users@sp.nitech.ac.jp>.
Subsequent modifications for the autoregressive HMM were made by
[Matt Shannon](mailto:matt.shannon@cantab.net).


[hts]: http://hts.sp.nitech.ac.jp/ "HMM-based Speech Synthesis System (HTS)"
[hts_demo]: http://hts.sp.nitech.ac.jp/?Download
[straight]: http://www.wakayama-u.ac.jp/~kawahara/STRAIGHTadv/index_e.html
[arctic]: http://festvox.org/cmu_arctic/
