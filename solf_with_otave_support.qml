import QtQuick 2.2
import MuseScore 3.0

MuseScore {
    version: "3.6.1"
    description: "Render tonic solfa syllables onto score"

    //---------------------------------------------------------
    // SETTINGS
    //---------------------------------------------------------

    property real smallScale: 0.8

    property var solfa: ['d','de','r','re','m','f','fe','s','se','l','ta','t']

    property var sharpKeys: ['C','G','D','A','E','B','F#','C#']
    property var flatKeys:  ['C','F','Bb','Eb','Ab','Db','Gb']

    property var enharmonic: ({
        'A#':'Bb','C#':'Db','D#':'Eb','F#':'Gb','G#':'Ab',
        'Bb':'A#','Db':'C#','Eb':'D#','Gb':'F#','Ab':'G#',
        'Cb':'B','Fb':'E','E#':'F','B#':'C'
    })

    property var tpcNames: [
        "Cbb","Gbb","Dbb","Abb","Ebb","Bbb",
        "Fb","Cb","Gb","Db","Ab","Eb","Bb",
        "F","C","G","D","A","E","B",
        "F#","C#","G#","D#","A#","E#","B#",
        "F##","C##","G##","D##","A##","E##","B##"
    ]

    //---------------------------------------------------------
    // KEY HELPERS
    //---------------------------------------------------------

    function keyFromSignature(sig){
        sig = Math.max(-6, Math.min(7, sig))
        return sig >= 0 ? sharpKeys[sig] : flatKeys[-sig]
    }

    function chromaticScaleFromKey(sig){

        var tonic = keyFromSignature(sig)

        var sharp = ['A','A#','B','C','C#','D','D#','E','F','F#','G','G#']
        var flat  = ['A','Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab']

        var ref = tonic.includes("b") ? flat : sharp
        var start = ref.indexOf(tonic)

        var scale=[]
        for(var i=0;i<12;i++)
            scale.push(ref[(start+i)%12])

        return scale
    }

    //---------------------------------------------------------
    // NOTE HELPERS
    //---------------------------------------------------------

    function tpcToLetter(tpc){
        if(tpc<0 || tpc>=tpcNames.length)
            return "?"
        return tpcNames[tpc]
    }

   function octaveDots(pitch){
    var octave = Math.floor(pitch/12)-1
    var out = ""

    if(octave > 4){
        for(var i=0;i<octave-4;i++)
            out += "'"
    }
    else if(octave < 4){
        for(var j=0;j<4-octave;j++)
            out += ","
    }

    return out
}

    function solfaForNote(scale,tpc,pitch){

        var letter = tpcToLetter(tpc)
        if(letter=="?") return "?"

        var idx = scale.indexOf(letter)

        if(idx==-1 && enharmonic[letter])
            idx = scale.indexOf(enharmonic[letter])

        if(idx==-1) return "?"

        return solfa[idx] + octaveDots(pitch)
    }

    //---------------------------------------------------------
    // TEXT RENDER
    //---------------------------------------------------------

    function renderChord(chord,scale){

        var text = newElement(Element.STAFF_TEXT)

        var out=""

        for(var i=0;i<chord.notes.length;i++){

            var n = chord.notes[i]
            if(!n.visible) continue

            if(out!=="") out+="\n"

            out += solfaForNote(scale,n.tpc,n.pitch)
        }

        if(out==="") return null

        text.text = out
        text.fontSize = 10 * smallScale

        return text
    }

    //---------------------------------------------------------
    // MAIN
    //---------------------------------------------------------

    onRun:{
        if(!curScore)
            return

        curScore.startCmd()

        var cursor = curScore.newCursor()

        for(var staff=0; staff<curScore.nstaves; staff++){
        for(var voice=0; voice<4; voice++){

            cursor.staffIdx = staff
            cursor.voice = voice
            cursor.rewind(0)

            var scale = chromaticScaleFromKey(cursor.keySignature)

            while(cursor.segment){

                if(cursor.keySignature!==undefined)
                    scale = chromaticScaleFromKey(cursor.keySignature)

                if(cursor.element && cursor.element.type===Element.CHORD){

                    var txt = renderChord(cursor.element,scale)

                    if(txt){

                        if(voice==1 || voice==3)
                            txt.placement = Placement.BELOW

                        cursor.add(txt)
                    }
                }

                cursor.next()
            }
        }}

        curScore.endCmd()
        Qt.quit()
    }
}
