functor
import
   Project2025
   OS
   System
   Property
   PartitionToTimedList
export
   mix:Mix
define
   CWD = {Atom.toString {OS.getCWD}}#"/"

   fun {Mix P2T Music}
      case P2T of
         nil then nil
      [] _ then
         {SampleCalc P2T}
      else {MixPart P2T Music}
      end
   end

   fun {SampleCalc P2T}
      case P2T of
         nil then nil
      [] H|T then
         Sample1 = {NoteToSample H}
         RestSample = {SampleCalc T}
      in
         {Append Sample1 RestSample}
      case Music of nil then nil
      [] Part|Rest then
         PartSamples = {MixPart P2T Part}
         RestSamples = {Mix P2T Rest}
      in
         {Append PartSamples RestSamples}
      end
   end

   %MixPart analyse le type de morceau dans l'argument Music de {Mix}
   fun {MixPart P2T Part}
      case Part of samples(S) then S

      [] partition(P) then
         {SampleCalc {ParitionToTimedList.ParitionToTimedList P}}

      [] wave(Fileneme) then
         {Project2025.load Filename}
      
      []merge(L) then 
         {MergeMusic P2T L}

      [] repeat(amount:A M) then
         {RepeatMusic A {Mix P2T M}}

      []loop(duration:D M) then
         {LoopMusic D {Mix P2T M}}

      []clip(low:L high:H M) then 
         {ClipMusic L H {Mix P2T M}}

      []echo(delay:D decay:Dec repeat:R M) then
         {EchoMusic D Rec R {Mix P2T M}}

      []fade(start:S finish:F M) then 
         {FadeMusic S F {Mix PT M}}

      []cut(start:S finish:F M) then
         {CutMusic S F {Mix PT M}}
      end
   end

   %MergeMusic permet de fusionner 2 liste de musique
   fun {MergeMusic P2T L} 
      Signals = {Map L fun {$ F#M} {ScaleSignal F {Mix P2T M}} end}
   in
      {MergeSignals Signals}
   end
   
   %ScaleSignal multiplie chaque Sample par un facteur
   fun {ScaleSignal Factor Signal}
      case Signal of nil then nil
      [] X|Xs then (X*Factor)|{ScaleSignal Factor Xs}
      end
   end

   %Additione les valeurs de chaque élément un a un
   fun {MergeSignals Signals}
      fun {Sum L1 L2}
         case L1#L2 of
            nil#nil then nil
         [] X1|T1 # nil then X1 | {Sum T1 nil}
         [] nil # X2|T2 then X2 | {Sum nil T2}
         [] X1|T1 # X2|T2 then (X1+X2) | {Sum T1 T2}
         end
      end
   in
      case Signals of
         nil then nil
      [] S|Ss then {FoldL Ss S Sum}
      end
   end
   
   %Repeat la musique N fois
   fun {RepeatMusic N Music}
      if N <= 0 then nil
      else {Append Music {RepeatMusic N-1 Music}}
      end
   end

   fun {LoopMusic D Music}

   

   fun {NoteToSample Note}
      local
         SampleRate = 44100.0
         Pi = 3.14159265359
         BaseFreq = 440.0
         NameToSemi = [a#9 b#11 c#0 d#2 e#4 f#5 g#7]
      in
         case Note of
            note(duration:D instrument:_ name:N octave:O sharp:S) then 
               Semi = {List.assoc NameToSemi N}
               RealSemi = Semi - 9 + 12 * (O - 4) + (if S then 1 else 0 end)
               Freq = BaseFreq * {Pow 2.0 (RealSemi / 12.0)}
               Len = {FloatToInt D * SampleRate}
               fun {Gen I}
                  if I >= Len then nil
                  else
                     T = {IntToFloat I} / SampleRate
                     Sample = 0.5 * {Sin 2.0 * Pi * Freq * T}
                  in
                     Sample | {Gen I + 1}
                  end
               end
            in
               {Gen 0}

         [] silence(duration:D) then
            Len = {FloatToInt D * SampleRate}
            fun {Gen I}
               if I >= Len then nil
               else 0.0 | {Gen I + 1}
               end
            end
         in
            {Gen 0}
         end
      end
   end
end