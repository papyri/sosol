Notes 2014-06-23:

1. any calls to set_content need to be checked --- either use set_xml_content or add actor info to options. Need to investigate what actor needs to be set to.

2. perseus epidoc stylesheets are not compiling. might be due to discrepancies between version of default epidoc xslt templates referenced from them in this branch the the version used in perseus_shibboleth

Notes 2014-07-01:

1. Left off with failure on retrieval of sentence from treebank file - to investigate

2. need to html_safe all transforms which bring xml/html into the display

3. need to cleanup setup of exist application tools template html files for paths
Notes 2014-07-03:

1. make sure all perseus config files are updated with latest settings (missing identifier types in application.rb)

2. create backup of bare minimum exist install (make sure has alignment, treebank code, sosol repo, cts code)

3. sort out path problems with tool integration (proxy, 3000, sosol)

4. review all http requests for encoding
