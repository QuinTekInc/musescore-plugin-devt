
import QtQuick 2.2
import MuseScore 3.0


MuseScore{

    requiresScore: true

    property var tonicSolfas: ['d', 'de', 'r', 're', 'm', 'f', 'fe', 's', 'se', 'l', 'te', 't']
    property var musicLettersSharp:  ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']
    property var musicLettersFlat: ['A', 'Bb', 'B', 'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab']

    property var accEquivalentMap: {
        'A#': 'Bb',
        'B#': 'C',
        'C#': 'Db',
        'D#': 'Eb',
        'E#': 'F',
        'F#': 'Gb',
        'G#': 'Ab',
        'Ab': 'G#',
        'Bb': 'A#',
        'Cb': 'B',
        'Db': 'C#',
        'Eb': 'D#',
        'Fb': 'E',
        'Gb': 'F#',
    }
    
    
    function getObjectType(object){
        return Object.prototype.toString.call(object);
    }
    
    
    
    function getMusicLetterFromFifth(keySig){
        var fifthKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#'];
        var fourthKeys = ['C', 'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb']

        return keySig >= 0 ? fifthKeys[keySig] : fourthKeys[-keySig];
    }



    function generateKeyScale(keySig){

        var musicLetter = getMusicLetterFromFifth(keySig);

        var priorityRef = musicLettersSharp;

        //check if the music letter contains sharps of flats
        if(musicLetter.includes('b')){
            priorityRef = musicLettersFlat;
        }


        //get the index of the music letter
        var startIndex = priorityRef.indexOf(musicLetter)

        var keyScale = [];

        for(var i = 0; i < priorityRef.length; i++){
            keyScale.push(priorityRef[(startIndex + i) % priorityRef.length]);
        }

        return keyScale;
    }


    function tonicSolfaForLetter(keyScale, tpc){


        var noteLetter = tpcToNoteLetter(tpc);
        console.log('TPC Note: ', noteLetter);

        var stepsMap = {'#': 1, 'b': -1};


        var isNatural = !(noteLetter.includes('#') || noteLetter.includes('b'));
        var foundInScale = keyScale.indexOf(noteLetter) !== -1;

        if(isNatural || foundInScale){
            return tonicSolfas[keyScale.indexOf(noteLetter)];
        }


        //get the accidentals in the note letter
        var accidentals = noteLetter.substring(1, noteLetter.length);

        if(accidentals.length == 1){
            //if the note letter has only one sharp or flat and that note letter is not in the key scale
            //find the alternate note letter that can be found in the keyscale
            var altNoteLetter = accEquivalentMap[noteLetter];

            var containsAltNoteLetter = keyScale.indexOf(altNoteLetter) !== -1;

            if(contains){
                return tonicSolfas[keyScale.indexOf(altNoteLetter) % keyScale.length];
            }

            return '?';
        }


        //now if execution reaches here, it means the accidentals found was more than one
        //example B## would be B#
        var reducedNoteLetter = noteLetter.substring(0, 2);

        var containsReducedLetter = keyScale.indexOf(reducedNoteLetter) !== -1;

        if(!containsReducedLetter){
            reducedNoteLetter = accEquivalentMap[reducedNoteLetter];
        }

        var index = keyScale.indexOf(reducedNoteLetter) + (stepsMap[accidentals.charAt(0)] * (accidentals.length - 1));

        var newMusicLetter = keyScale[index % keyScale.length];

        return tonicSolfas[index % keyScale.length];

    }



    function tpcToNoteLetter(tpc){

        if(tpc < -1) return '?';

        if(tpc == -1) return 'Fbb';

        //note that: Musescore uses tpc values.

        var tpcNames = [
            "Cbb", "Gbb", "Dbb", "Abb", "Ebb", "Bbb",       // 0 - 5 [DOUBLE FLATS]

            "Fb", "Cb",  "Gb",  "Db",  "Ab",  "Eb", "Bb",   // 6 - 12 [SINGLE FLATS]

            "F",   "C",   "G",   "D",  "A", "E", "B",       //13 - 19 [NATURALS]

            "F#",  "C#",  "G#",  "D#", "A#",  "E#",  "B#",  //20 - 26  [SINGLE SHARPS]

            "F##", "C##", "G##", "D##", "A##", "E##", "B##"  // 27 - 33 [DOUBLE SHARPS]
        ];

        if (tpc >= 0 && tpc < tpcNames.length) {
            return tpcNames[tpc];
        }

        return "?";
    }


    
    function renderChords(keyScale, notes){
      //this function is used to render chords as text 
    }

    function graceNotes(keyScale, graceNotes){
      //this function renders grace notes to the text
    }


    function numberOfStaves(part){
        return (part.endTrack - part.startTrack) / 4;
    }


    function extractPart(part, startIndex, endIndex){

        //console.log(part.partName, ': ', startIndex, ' -> ', endIndex);

        var instruments = part.instruments;
        
        //iterate check if the part uses a pitched instrument or not
        if(instruments[0].useDrumset){
            console.log('This part uses in a unpitched instrument');
            return;
        }

        var staves = numberOfStaves(part);


        var keyScale = undefined;

        var measureCount = curScore.nMeasures;


        for(var staff = startIndex; staff <= endIndex; staff++){
            
            //iterate through the measures in the staff.
            var cursor = curScore.newCursor();
            cursor.staffIdx = staff;
            cursor.rewind(0);

            if(cursor.keySignature){
                keyScale = generateKeyScale(cursor.keySignature);
            }


            while(cursor.segment){
                
                for(var anot = 0; anot < cursor.segment.annotations.length; anot++){
                    var element = cursor.segment.annotations[anot];

                    switch(element.type){
                        case Element.KEY_SIG:
                            keyScale = generateKeyScale(element.key);
                            console.log('Key change detected.');
                            break;
                        
                        case Element.CHORD:
                            console.log('Found a chord')

                            break;

                        case Element.REST:
                            console.log('Encountered rest here')
                            break;

                        default: 
                            console.log('Could not determine the element type');
                            break;
                    }


                }


                cursor.next();

            }

        }

    }



    function renderNotes(notes, keyScale){

    }



    function getScoreInfo(){
        var score_title = curScore.title;
        var measures = curScore.nmeasures;

        console.log('Score Title: ', score_title);
        console.log("Staves: ", curScore.nstaves);
        console.log('Measures: ', measures);
        console.log('Parts: ', curScore.parts.length);
    }

    onRun: {

        var scale = generateKeyScale(0);
        var tonic = tonicSolfaForLetter(scale, 10);
        console.log(tonic);

        Qt.quit();
    
    
        if(curScore == 'undefined' || !curScore){
            console.log('No score has been loaded');
            return;
        }

        curScore.startCmd();

        getScoreInfo();

        //get the current score is accessed, by the curScore variable

        var nstaves = curScore.nstaves;
        var parts = curScore.parts;
        
        var partCounter = 0;
        var staveCounter = 0;

        for(var p = 0; p < parts.length; p++){

            var part = parts[p];
            var partNStaves = numberOfStaves(part)

            var endStaveIdx = staveCounter + (partNStaves - 1);

            extractPart(part, staveCounter, endStaveIdx);

            staveCounter += partNStaves; 
        }
        
        Qt.quit()
        

    }
}