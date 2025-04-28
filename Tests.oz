functor
import
   Project2025
   Mix
   System
   Property
export
   test: Test
define

   PassedTests = {Cell.new 0}
   TotalTests  = {Cell.new 0}

   FiveSamples = 0.00011337868 % Duration to have only five samples

   % Takes a list of samples, round them to 4 decimal places and multiply them by
   % 10000. Use this to compare list of samples to avoid floating-point rounding
   % errors.
   fun {Normalize Samples}
      {Map Samples fun {$ S} {IntToFloat {FloatToInt S*10000.0}} end}
   end

   proc {Assert Cond Msg}
      TotalTests := @TotalTests + 1
      if {Not Cond} then
         {System.show Msg}
      else
         PassedTests := @PassedTests + 1
      end
   end

   proc {AssertEquals A E Msg}
      TotalTests := @TotalTests + 1
      if A \= E then
         {System.show Msg}
         {System.show actual(A)}
         {System.show expect(E)}
      else
         PassedTests := @PassedTests + 1
      end
   end
   fun {RepeatNote N A}
      if N =< 0 then nil
      else A | {RepeatNote N-1 A}
      end
   end
   

   fun {NoteToExtended Note}
      case Note
      of note(...) then
         Note
      [] silence(duration: _) then
         Note
      [] _|_ then
         {Map Note NoteToExtended}
      [] nil then
         nil
      [] silence then
         silence(duration:1.0)
      [] Name#Octave then
         note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
         case {AtomToString Atom}
         of [_] then
            note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
         [] [N O] then
            note(name:{StringToAtom [N]}
                 octave:{StringToInt [O]}
                 sharp:false
                 duration:1.0
                 instrument: none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TEST PartitionToTimedNotes

   proc {TestNotes P2T}
      P1 = [a0 b1 c#2 d#3 e silence]
      E1 = {Map P1 NoteToExtended}
   in
      {AssertEquals {P2T P1} E1 "TestNotes"}
   end

   proc {TestChords P2T}
      skip
   end

   proc {TestIdentity P2T}
      % test that extended notes and chord go from input to output unchanged
      skip
   end

   proc {TestDuration P2T}
      Original = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)
                  silence(duration:1.0)]
      P = [duration(seconds:4.0 Original)]
      Expected = [note(name:a octave:4 sharp:false duration:2.0 instrument:none)
                  silence(duration:2.0)]
   in
      {AssertEquals {P2T P} Expected "TestDuration: scaling from 2.0 to 4.0"}
   end
   

   proc {TestStretch P2T}
      Original = [note(name:c octave:4 sharp:false duration:1.0 instrument:none)
                  silence(duration:2.0)]
      P = [stretch(factor:0.5 Original)]
      Expected = [note(name:c octave:4 sharp:false duration:0.5 instrument:none)
                  silence(duration:1.0)]
   in
      {AssertEquals {P2T P} Expected "TestStretch: factor 0.5"}
   end
   

   proc {TestDroneNote P2T}
      P = [drone(note: c amount: 3)]
      E = {RepeatNote 3 note(name: c octave: 4 sharp: false duration: 1.0 instrument: none)}

   in
      {AssertEquals {P2T P} E "TestDrone: single note"}
   end
   
   proc {TestDroneChord P2T}
      C = [drone(note: [c e g] amount: 2)]
      EC = {RepeatNote 2
            [note(name: c octave: 4 sharp: false duration: 1.0 instrument: none)
              note(name: e octave: 4 sharp: false duration: 1.0 instrument: none)
              note(name: g octave: 4 sharp: false duration: 1.0 instrument: none)]}
   in
      {AssertEquals {P2T C} EC "TestDrone: chord"}
   end
   
   proc {TestDrone P2T}
      {TestDroneNote P2T}
      {TestDroneChord P2T}
   end
   
   

   proc {TestMute P2T}
      E = {RepeatNote 3 [silence(duration:1.0)]}
   in
      {AssertEquals {P2T [mute(amount:3)]} E "TestMute: 3 silences"}
   end
   

   proc {TestTranspose P2T}
      In = [transpose(semitones:1 [a])]
      E = [note(name: a octave: 4 sharp: true duration: 1.0 instrument: none)]

   in
      {AssertEquals {P2T In} E "TestTranspose: A → A#"}
   end
   

   proc {TestP2TChaining P2T}
      skip
   end

   proc {TestEmptyChords P2T}
     skip
   end
      
   proc {TestP2T P2T}
      {TestNotes P2T}
      {TestChords P2T}
      {TestIdentity P2T}
      {TestDuration P2T}
      {TestStretch P2T}
      {TestDrone P2T}
      {TestMute P2T}
      {TestTranspose P2T}
      {TestP2TChaining P2T}
      {TestEmptyChords P2T}   
      {AssertEquals {P2T nil} nil 'nil partition'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TEST Mix

   proc {TestSamples P2T Mix}
      E1 = [0.1 ~0.2 0.3]
      M1 = [samples(E1)]
   in
      {AssertEquals {Mix P2T M1} E1 'TestSamples: simple'}
   end
   
   proc {TestPartition P2T Mix}
      skip
   end
   
   proc {TestWave P2T Mix}
      skip
   end

   proc {TestMerge P2T Mix}
      skip
   end

   proc {TestReverse P2T Mix}
      skip
   end

   proc {TestRepeat P2T Mix}
      skip
   end

   proc {TestLoop P2T Mix}
      skip
   end

   proc {TestClip P2T Mix}
      skip
   end

   proc {TestEcho P2T Mix}
      skip
   end

   proc {TestFade P2T Mix}
      skip
   end

   proc {TestCut P2T Mix}
      skip
   end

   proc {TestMix P2T Mix}
      {TestSamples P2T Mix}
      {TestPartition P2T Mix}
      {TestWave P2T Mix}
      {TestMerge P2T Mix}
      {TestRepeat P2T Mix}
      {TestLoop P2T Mix}
      {TestClip P2T Mix}
      {TestEcho P2T Mix}
      {TestFade P2T Mix}
      {TestCut P2T Mix}
      {AssertEquals {Mix P2T nil} nil 'nil music'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   proc {Test Mix P2T}
      {Property.put print print(width:100)}
      {Property.put print print(depth:100)}
      {System.show 'tests have started'}
      {TestP2T P2T}
      {System.show 'P2T tests have run'}
      {TestMix P2T Mix}
      {System.show 'Mix tests have run'}
      {System.show test(passed:@PassedTests total:@TotalTests)}
   end
end