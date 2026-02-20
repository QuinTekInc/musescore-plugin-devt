import QtQuick 2.2
import MuseScore 3.0

MuseScore {
    version: "3.6.1"
    description: "Render tonic solfa syllables onto score"

    property real fontSizeMini: 0.8

    property var tonicSolfas: ['d','de','r','re','m','f','fe','s','se','l','ta','t']

    property var musicLettersSharp:  ['A','A#','B','C','C#','D','D#','E','F','F#','G','G#']
    property var musicLettersFlat:   ['A','Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab']

    property var accEquivalentMap: ({
        'A#':'Bb','B#':'C','C#':'Db','D#':'Eb','E#':'F','F#':'Gb','G#':'Ab',
        'Ab':'G#','Bb':'A#','Cb':'B','Db':'C#','Eb':'D#','Fb':'E','Gb':'F#'
    })

    //----------------------------------------------------------
    // KEY + SCALE LOGIC
    //----------------------------------------------------------

    function getMusicLetterFromFifth(keySig){
        var fifthKeys  = ['C','G','D','A','E','B','F#','C#']
        var fourthKeys = ['C','F','Bb','Eb','Ab','Db','Gb']
        return keySig >= 0 ? fifthKeys[keySig] : fourthKeys[-keySig]
    }

    function generateKeyScale(keySig){
        var tonic = getMusicLetterFromFifth(keySig)
        var ref = tonic.includes("b") ? musicLettersFlat : musicLettersSharp
        var start = ref.indexOf(tonic)

        var scale=[]
        for(var i=0;i<ref.length;i++)
            scale.push(ref[(start+i)%ref.length])

        return scale
    }

    //----------------------------------------------------------
    // TPC → LETTER
    //----------------------------------------------------------

    function tpcToLetter(tpc){
        var names=[
            "Cbb","Gbb","Dbb","Abb","Ebb","Bbb",
            "Fb","Cb","Gb","Db","Ab","Eb","Bb",
            "F","C","G","D","A","E","B",
            "F#","C#","G#","D#","A#","E#","B#",
            "F##","C##","G##","D##","A##","E##","B##"
        ]
        if(tpc<0 || tpc>=names.length) return "?"
        return names[tpc]
    }

    //----------------------------------------------------------
    // LETTER → TONIC SOLFA
    //----------------------------------------------------------

    function solfaForTPC(scale,tpc){
        var letter = tpcToLetter(tpc)
        if(letter=="?") return "?"

        var index = scale.indexOf(letter)
        if(index!=-1)
            return tonicSolfas[index]

        var alt = accEquivalentMap[letter]
        if(alt){
            index = scale.indexOf(alt)
            if(index!=-1)
                return tonicSolfas[index]
        }
        return "?"
    }

    //----------------------------------------------------------
    // RENDER NOTE TEXT
    //----------------------------------------------------------

    function renderChordSolfa(notes,text,scale,small){

        var sep="\n"

        for(var i=0;i<notes.length;i++){
            if(!notes[i].visible) continue

            var solfa = solfaForTPC(scale,notes[i].tpc)

            if(text.text)
                text.text = sep + text.text

            if(small)
                text.fontSize *= fontSizeMini

            text.text = solfa + text.text
        }
    }

    //----------------------------------------------------------
    // MAIN LOOP
    //----------------------------------------------------------

    onRun:{
        if(!curScore) return

        curScore.startCmd()

        var cursor = curScore.newCursor()
        cursor.rewind(0)

        var keyScale = generateKeyScale(cursor.keySignature)


        for(var staff=0; staff<curScore.nstaves; staff++){
            
        
            for(var voice=0; voice<4; voice++){

                cursor.staffIdx = staff
                cursor.voice = voice
                cursor.rewind(0)

                while(cursor.segment){

                    if(cursor.keySignature!==undefined)
                        keyScale = generateKeyScale(cursor.keySignature)

                    if(cursor.element && cursor.element.type===Element.CHORD){

                        var chord = cursor.element
                        var text = newElement(Element.STAFF_TEXT)

                        renderChordSolfa(chord.notes,text,keyScale,true)

                        if(text.text)
                            cursor.add(text)

                        if(cursor.voice==1 || cursor.voice==3)
                            text.placement = Placement.BELOW
                    }

                    cursor.next()
                }
            }
        }

        curScore.endCmd()
        Qt.quit()
    }
}
