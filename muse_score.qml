import MuseScore 4.0
import QtQuick 2.15

MuseScore {
    version: "4.0.0"
    description: "Render tonic solfa syllables for MS4"

    //---------------------------------------------------------
    // SETTINGS (Maintaining your exact naming)
    //---------------------------------------------------------
    property real smallScale: 0.8
    property var solfa: ['d','de','r','re','m','f','fe','s','se','l','ta','t']
    property var octaveScripts: ({
        "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "-1": "₁", "-2": "₂", "-3": "₃", "-4": "₄"
    })

    //---------------------------------------------------------
    // HELPERS (Updated for MS4 Logic)
    //---------------------------------------------------------

    function tpcToLetter(tpc) {
        // MS4 TPC mapping is identical to MS3
        var names = ["Cbb","Gbb","Dbb","Abb","Ebb","Bbb","Fb","Cb","Gb","Db","Ab","Eb","Bb","F","C","G","D","A","E","B","F#","C#","G#","D#","A#","E#","B#","F##","C##","G##","D##","A##","E##","B##"];
        return (tpc >= 0 && tpc < names.length) ? names[tpc] : "?";
    }

    function generateScaleOctaveMap(tonic, clefOctave) {
        var map = {};
        var notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        var idx = notes.indexOf(tonic);
        var octave = clefOctave;

        for (var i = 0; i < 12; i++) {
            var currentNote = notes[(idx + i) % 12];
            // The "C-Boundary" Fix: Match MIDI/MS4 internal pitch flip
            if (i > 0 && currentNote === "C") {
                octave++;
            }
            map[currentNote] = octave;
        }
        return map;
    }

    function solfaForNote(scale, tpc, note, clefType) {
        var letter = tpcToLetter(tpc);
        if (letter === "?") return "?";

        // FIX: Use ppitch (Played/Written Pitch) to avoid the "70 vs 72" Bb Trumpet bug
        var writtenPitch = note.ppitch; 
        
        // Use Math.round to kill the 71.999 floating point jitter
        var noteOctave = Math.round(writtenPitch / 12) - 1;

        var idx = scale.indexOf(letter);
        if (idx === -1) return "?";

        var tonicSyllable = solfa[idx];
        var defaultOctave = (clefType === 1) ? 3 : 4; // Bass=3, Treble=4
        
        var octaveScaleMap = generateScaleOctaveMap(scale[0], defaultOctave);
        var noteScaleOctave = octaveScaleMap[letter];

        var octaveDiff = noteOctave - noteScaleOctave;
        if (octaveDiff === 0) return tonicSyllable;
        return tonicSyllable + (octaveScripts[octaveDiff] || "");
    }

    function renderChord(chord, scale, clefType) {
        var text = newElement(Ms.Element.STAFF_TEXT);
        var out = "";

        for (var i = 0; i < chord.notes.length; i++) {
            var n = chord.notes[i];
            if (!n.visible) continue;
            if (out !== "") out += "\n";
            // Pass the whole 'note' object to access ppitch
            out += solfaForNote(scale, n.tpc, n, clefType);
        }

        if (out === "") return null;
        text.text = out;
        text.fontSize = 10 * smallScale;
        return text;
    }

    //---------------------------------------------------------
    // MAIN
    //---------------------------------------------------------
    onRun: {
        if (!curScore) return;
        curScore.startCmd();

        var cursor = curScore.newCursor();

        for (var staff = 0; staff < curScore.nstaves; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staff;
                cursor.voice = voice;
                cursor.rewind(0); // Rewind to start

                // MS4 handles clefs and keys directly on the cursor/staff
                var currentClef = cursor.staff.clefType;
                
                while (cursor.segment) {
                    // Check for mid-measure clef changes
                    for (var i = 0; i < cursor.segment.annotations.length; i++) {
                        var ann = cursor.segment.annotations[i];
                        if (ann.type === Ms.Element.CLEF) {
                            currentClef = ann.clefType;
                        }
                    }

                    if (cursor.element && cursor.element.type === Ms.Element.CHORD) {
                        // chromaticScaleFromKey logic remains similar to your MS3 helper
                        // Assumed 'scale' is passed here from your key signature logic
                        var scale = ["F","G","A","Bb","C","D","E"]; // Placeholder for key logic
                        
                        var txt = renderChord(cursor.element, scale, currentClef);
                        if (txt) {
                            if (voice === 1 || voice === 3) txt.placement = Ms.Placement.BELOW;
                            cursor.add(txt);
                        }
                    }
                    cursor.next();
                }
            }
        }
        curScore.endCmd();
    }
}