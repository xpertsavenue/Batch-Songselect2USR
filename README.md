# Batch-Songselect2USR
This simple perl scripts fetches a whole songbook from www.liederdatenbank.de, searches Songselect CCLI for matchinbg songs and downloads the songs in the old USR-fileformat. After Download you can gibe the songs a name that is generated from the title, the author and ccli number.  
You can import the songs to nearly every song presenting progam.

## Prepare programm
Open the AllSteps_FetchSongs.pl with your texteditor and search for the lines

```
my $username = 'your_username';
my $password = 'your_password';
```
and enter you login from Songselect CCLI.
make sure perl is installed and added to commandline.

## Using the programm
There are 5 steps that you can run:
  1 Provide a link to www.liederdatenbank.de and the programm fetchs all songs that are named on the page and saved it to a CSV-File (Paramter: link to www.liederdatenbank.de)
  2 Linking the songs from CSV from step 1 to and give each a CCLI number. Note somthimes the matching algorithm did not found a song and somthimes there are more than one matching songs. All found songs will be saved in a CSV. You can edit the CSV in a texteditor a a calucalion program. (Parameter: CSV-file from step 1)
  3 Dowload the songs from the CSV from step 2 and save it to a directory called 'Step3_Download'
  4 Rename the songs and copy the files to 'Step4_SortetDownload/Import'
    after that you can import the songs to OpenLP or something else. After importing move the files from 'Step4_SortetDownload/Import' to 'Step4_SortetDownload'
  5 With the the last step you can create a database. All songs that are in the directory 'Step4_SortetDownload' will be in identified.

To use the programm you have to use commandline
```
perl AllSteps_FetchSongs.pl <step> <parameter: link or file>
```

or simple run the script by 
```
perl AllSteps_FetchSongs.pl 
```
and answer the questions asked by the console.

**IMPORTANT: Use the script just for your needs. Do not exaggerate!**

## License
MIT License

Copyright (c) 2018 Christian Beckert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
