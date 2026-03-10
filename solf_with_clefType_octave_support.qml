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

    //circle of fifths based (sharps)
    property var sharpKeys: ['C','G','D','A','E','B','F#','C#']
    //circle of fifths[fourths] (flats)
    property var flatKeys:  ['C','F','Bb','Eb','Ab','Db','Gb']

    property var cMajChromaticScale: chromaticScaleFromKey(0)

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


    property var clefOctaveMap: ({
        0: 4, //treble clef
        1: 3 //bass clef
    })


    property var octaveScripts: ({
        //superscripts
        //0: "⁰",
        1: "¹",
        2: "²",
        3: "³",
        4: "⁴",
        5: "⁵",
        6: "⁶",
        7: "⁷",
        8: "⁸",
        9: "⁹",

        //subscripts
        //0: "₀",
        "-1": "₁",
        "-2": "₂",
        "-3": "₃",
        "-4": "₄",
        "-5": "₅",
        "-6": "₆",
        "-7": "₇",
        "-8": "₈",
        "-9": "₉",

    })


    property var pitchList: (function(){
        var pitches = []
        for(var p = 1; p <= 128; p++) pitches.push(p)
        return pitches
    })()


    property var pitchToNote: {
        1:"C#",2:"D",3:"D#",4:"E",5:"F",6:"F#",7:"G",8:"G#",9:"A",10:"A#",11:"B",
        12:"C",13:"C#",14:"D",15:"D#",16:"E",17:"F",18:"F#",19:"G",20:"G#",21:"A",22:"A#",23:"B",
        24:"C",25:"C#",26:"D",27:"D#",28:"E",29:"F",30:"F#",31:"G",32:"G#",33:"A",34:"A#",35:"B",
        36:"C",37:"C#",38:"D",39:"D#",40:"E",41:"F",42:"F#",43:"G",44:"G#",45:"A",46:"A#",47:"B",
        48:"C",49:"C#",50:"D",51:"D#",52:"E",53:"F",54:"F#",55:"G",56:"G#",57:"A",58:"A#",59:"B",
        60:"C",61:"C#",62:"D",63:"D#",64:"E",65:"F",66:"F#",67:"G",68:"G#",69:"A",70:"A#",71:"B",
        72:"C",73:"C#",74:"D",75:"D#",76:"E",77:"F",78:"F#",79:"G",80:"G#",81:"A",82:"A#",83:"B",
        84:"C",85:"C#",86:"D",87:"D#",88:"E",89:"F",90:"F#",91:"G",92:"G#",93:"A",94:"A#",95:"B",
        96:"C",97:"C#",98:"D",99:"D#",100:"E",101:"F",102:"F#",103:"G",104:"G#",105:"A",106:"A#",107:"B",
        108:"C",109:"C#",110:"D",111:"D#",112:"E",113:"F",114:"F#",115:"G",116:"G#",117:"A",118:"A#",119:"B",
        120:"C",121:"C#",122:"D",123:"D#",124:"E",125:"F",126:"F#",127:"G", 128:"G#"
    }


    property var transpositionMap: {
        'G': -5,
        'G#': -4,
        'A': -3,
        'A#': -2,
        'B': -1,
        'C': 0,
        'C#': 1, 
        'D': 2,
        'Eb': 3,
        'E': 4,
        'F': 5,
        'F#': 6 //or -6
    }

    //---------------------------------------------------------
    // KEY HELPERS
    //---------------------------------------------------------

    function keyFromSignature(sig){
        sig = Math.max(-7, Math.min(7, sig))
        return sig >= 0 ? sharpKeys[sig] : flatKeys[-sig]
    }

    function chromaticScaleFromKey(sig){

        var tonic = keyFromSignature(sig)

        var sharp = ['A','A#','B','C','C#','D','D#','E','F','F#','G','G#']
        var flat  = ['A','Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab']

        var ref = tonic.includes("b") ? flat : sharp
        var start = ref.indexOf(tonic)

        var scale = []

        for(var i=0;i<12;i++)
            scale.push(ref[(start+i)%12])

        return scale
    }

    
    function extractMajorScale(scale){

        var stepMap = {'s': 1, 't': 2}

        var steps = ['t', 't', 's', 't', 't', 't', 's']

        var majorScale =  [scale[0],]

        var index = 0

        for(var i = 0; i < steps.length; i++){

            var step = stepMap[steps[i]]
            var noteIndex = index + step

            var note = scale[noteIndex]

            majorScale.push(note)

            index = noteIndex

        }


        return majorScale

    }


    //a function to replace a particular key accidental with its alternate enharmonic
    function generateChromaticScaleEnharmonic(keySig){

        var originalScale = chromaticScaleFromKey(keySig)

        var enharmoicScale = []

        for(var i = 0; i < originalScale.length; i++){
            var letter = originalScale[i]

            if(letter.includes('b') || letter.includes('#')){
                letter = enharmonic[letter]
            }

            enharmoicScale.push(letter)
        }

        return enharmoicScale
    }


    function generateScaleOctaveMap(key, clefOctave){

        var map = {}

        var scale = cMajChromaticScale

        key = String(key)

        if(key !== "C" && flatKeys.indexOf(key) !== -1){
            scale = generateChromaticScaleEnharmonic(0) 
        }


        var idx = scale.indexOf(key)

        var octave = clefOctave

        for(var i= 0 ; i < scale.length;i++){

            var note = scale[(idx+i) % scale.length]

            map[note] = octave

           if(note === "B") octave++ //increase the octave before moving to the next note.
        }


        var majorScale = extractMajorScale(Object.keys(map))
        
        var values = []

        for(var m = 0; m < majorScale.length; m++){
            var k = majorScale[m]
            values.push(map[k])
        }

        
        console.log(values)


        return map
    }

    //---------------------------------------------------------
    // NOTE HELPERS
    //---------------------------------------------------------

    function tpcToLetter(tpc){
        if(tpc<0 || tpc>=tpcNames.length)
            return "?"
        return tpcNames[tpc]
    }

    function calcOctave(pitch, transposition){
        return Math.floor((pitch - transposition) / 12) - 1
    }


    function maxOf(arr){

        if(arr.length == 0) return undefined

        var m = arr[0]

        for(var i = 1; i < arr.length; i++){
           if(m < arr[i])
                m = arr[i]
        }

        return m
    }

    function minOf(arr){

        if(arr.length == 0) return undefined

        var m = arr[0]

        for(var i = 1; i < arr.length; i++){
           if(m > arr[i])
                m = arr[i]
        }

        return m
    }



    function calculateTranposition(pitch, musicLetter){

        if(musicLetter == '?') return 0

        //get the sounding letter corresponding to the pitch
        var pitchLetter = pitchToNote[pitch]

        //natural instruments. (C instruments)
        //if zero is returned it means the instrument is a C or Natural instrument.
        if(pitchLetter === musicLetter || enharmonic[pitchLetter] === musicLetter)
            return 0

        //using the CMajor Chromatic Scale as the references
        var scale = cMajChromaticScale

        //get the pitch letter offset [Sounding letter of the sounding pitch]
        var pitchChromOffset = scale.indexOf(pitchLetter)

        if(pitchChromOffset === -1) pitchChromOffset = scale.indexOf(enharmonic[pitchLetter])

        //get the chromatic offset of the written music letter.
        var writtenChromOffset = scale.indexOf(musicLetter) 

        if(writtenChromOffset === -1) writtenChromOffset = scale.indexOf(enharmonic[musicLetter])

        //find the difference when moving forward.
        //the formula is sounding offset by written offset.
        var diffForward = (pitchChromOffset - writtenChromOffset) % 12
    
        //find the differcence when moving forward
        //var diffRev = diffForward - 12
        var diffRev = stepBackward(pitchLetter, musicLetter, scale)
        
        console.log(diffRev)
        

        //get the least absolute value among the two differences
        var transp = Math.abs(diffForward) <= Math.abs(diffRev) ? diffForward : diffRev


        return transp
        
    }

    function stepBackward(pLetter, wLetter, scale){

        if(scale.indexOf(pLetter) === -1) pLetter = enharmonic[pLetter]

        var startIndex = scale.indexOf(pLetter)
        var currentIndex = startIndex

        var steps = 0

        while(scale[currentIndex] != wLetter){

            currentIndex -= 1

            if(currentIndex < 0){
                currentIndex = scale.length - 1
            }

            steps += 1
        }


        return steps

    }

   

    function solfaForNote(scale, tpc, pitch, clefType){

        var letter = tpcToLetter(tpc) 

        if(letter=="?") return "?"

        var idx = scale.indexOf(letter)
        
        //if the music letter for the current note is note found in the scale 
        //we get the alternate from the enharmonic dictionary
        if(idx == -1 && enharmonic[letter]) idx = scale.indexOf(enharmonic[letter])

        if(idx == -1) return "?"

        var tonic = solfa[idx]


        //get the default octave for the current clef.
        //we using 4 (GClef) as default octave. 
        var defaultOctave = clefOctaveMap[clefType] || 4


        //find the transposition using the souding pitch and the writte music letter
        var transposition = calculateTranposition(pitch, letter)
        
        //get the octave of the current music letter
        var noteOctave = calcOctave(pitch, transposition)

        //get the octave of the note/music letter in the scale
        var octaveScaleMap = generateScaleOctaveMap(scale[0], defaultOctave)

        var noteScaleOctave = octaveScaleMap[letter]

        if(noteScaleOctave == undefined){
            noteScaleOctave = octaveScaleMap[enharmonic[letter]]
        }

        //get the octave difference
        var octaveDiff = noteOctave - noteScaleOctave

        //return only the tonic solfa when within the natual octave
        if(octaveDiff === 0) return tonic

        return tonic + octaveScripts[octaveDiff]
    }

    //---------------------------------------------------------
    // TEXT RENDER
    //---------------------------------------------------------

    function renderChord(chord, scale, clefType){

        var text = newElement(Element.STAFF_TEXT)

        var out=""

        for(var i=0;i<chord.notes.length;i++){

            var n = chord.notes[i]

            if(!n.visible) continue

            if(n.staff !== undefined){
                
                if(n.staff.part !== undefined){
                    if(n.staff.hasDrumStaff) continue
                }
            }

            if(out!=="") out+="\n"

            out += solfaForNote(scale, n.tpc, n.pitch, clefType)
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

                var currentClef = 0 //treble clef by default

                var scale = chromaticScaleFromKey(cursor.keySignature)

                while(cursor.segment){


                    for (var i = 0; i < cursor.segment.annotations.length; i++) {
                        var ann = cursor.segment.annotations[i];
                        if (ann.type === Element.CLEF || ann.type === Element.HEADERCLEF) {
                            currentClef = ann.clefType;
                            console.log('Found clef changes')
                        }
                    }

                    if(cursor.keySignature!==undefined)
                        scale = chromaticScaleFromKey(cursor.keySignature)

                    if(cursor.element && cursor.element.type===Element.CHORD){

                        var txt = renderChord(cursor.element,scale, currentClef)

                        if(txt){

                            if(voice==1 || voice==3)
                                txt.placement = Placement.BELOW

                            cursor.add(txt)
                        }
                    }

                    cursor.next()
                }
            }
        }

        curScore.endCmd()
        Qt.quit()
    }
}