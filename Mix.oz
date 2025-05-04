functor
import
   Project2025
   OS
   System
   Property
export
   mix:Mix
define
   CWD = {Atom.toString {OS.getCWD}}#"/"

   fun {Mix P2T Music}
      case Music of
         nil then nil
      [] H|T then
         HeadSample = {MixPart P2T H}
         TailSamples = {Mix P2T T}
      in
         {Append HeadSample TailSamples} 
      end
   end

   %MixPart analyse le type de morceau dans l'argument Music de {Mix}
   fun {MixPart P2T Part}
      case Part of samples(S) then S

      []partition(P) then
         {SampleCalc {P2T P}}

      []wave(Filename) then
         {Project2025.load Filename}
      
      []merge(L) then 
         {MergeMusic P2T L}

      []repeat(amount:A M) then
         {RepeatMusic A {Mix P2T M}}

      []loop(duration:D M) then
         {LoopMusic D {Mix P2T M}}

      []clip(low:L high:H M) then 
         {ClipMusic L H {Mix P2T M}}

      []echo(delay:D decay:Dec repeat:R M) then
         {EchoMusic D Dec R {Mix P2T M}}

      []fade(start:S finish:F M) then 
         {FadeMusic S F {Mix P2T M}}

      []cut(start:S finish:F M) then
         {CutMusic S F {Mix P2T M}}
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
      [] H|T then (H*Factor)|{ScaleSignal Factor T}
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
      [] H|T then {FoldL T H Sum}
      end
   end
   
   %Repeat la musique N fois
   fun {RepeatMusic N Music}
      if N =< 0 then nil
      else {Append Music {RepeatMusic (N-1) Music}}
      end
   end

   %Répète la musique pour une durée D (en secondes)
   fun {LoopMusic Music D}
      SPS = 44100
      TS = D * SPS

      fun {RepeatMax Acc}
         Full = {Append Acc Music}
      in
         if {Length Full} >= TS then Full
         else {RepeatMax Full}
         end
      end
      FullSignal = {RepeatMax nil}
   in 
      {List.take FullSignal TS}
   end

   %Clip agit en tant que Equalizer, elle réstreint certaine fréquence
   fun {ClipMusic Low High Music}
      fun {ClipSample S}
         if S < Low then Low
         elseif S > High then High
         else S
         end
      end
   in
      {Map Music ClipSample}
   end

   %Echo ajoute un echo a la musique
   fun {EchoMusic D Dec R Music}
      SPS = 44100
      DelaySamples = {FloatToInt D * SPS}

      fun {GenerateEchoes N}
         if N == 0 then nil
         else
            DecayFactor = {Pow Dec N}
            Echoed = {ScaleSignal DecayFactor Music}
            Delayed = {Append {Silence D * N} Echoed}
         in
            Delayed | {GenerateEchoes N-1}
         end
      end
      AllSignals = Music | {GenerateEchoes R-1}
   in
      {MergeSignals AllSignals}
   end  

   fun {FadeMusic S F Music}
      SPS = 44100.0
      Start = {FloatToInt S * SPS}
      Finish = {FloatToInt F * SPS}
      Len = {Length Music}

      fun {Fade L I}
         case L of nil then nil
         []H|T then 
            if I < Start then F = {IntToFloat I} / {IntToFloat Start}
            elseif I >= Len - Finish then 
               F = {IntToFloat (Len - I)} / {IntToFloat Finish}
            else
               F = 1.0
            end
         in
            (H * F)|{Fade T I+1}
         end
      end
   in
      {Fade Music 0}
   end

   fun {CutMusic S F Music}
      SPS = 44100.0
      Start = {FloatToInt (S * SPS)}
      End = {FloatToInt (F * SPS)}
      Len = {Length Music}

      fun {Cut I}
         if I >= End then nil
         else
            Sample = if I < Len then {List.nth Music I+1}
            else
               0.0
            end
         in Sample | {Cut I+1}
         end
      end
   in
      {Cut Start}
   end
   
   %Crée un silence de X secondes
   fun {Silence Seconds}
      SPS = 44100
      Length = {Float.toInt Seconds * SPS}
   in
      {List.make Length 0}
   end

   fun {SampleCalc P2T}
      case P2T of nil then nil
      [] H|T then
         Sample1 = {NoteToSample H}
         RestSample = {SampleCalc T}
      in
         {Append Sample1 RestSample}
      end
   end

   fun {NoteToSample Note}
      local
         SampleRate = 44100.0
         Pi = 3.14159265359
         BaseFreq = 440.0
         NameToSemi = [a#9 b#11 c#0 d#2 e#4 f#5 g#7]
      in
         case Note of
            note(duration:D instrument:_ name:N octave:O sharp:S) then 
               Semi = {IntToFloat{Assoc N NameToSemi}}
               RealSemi = Semi - 9.0 + 12.0 * ({IntToFloat O} - 4.0) + (if S then 1.0 else 0.0 end)
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

   fun {Assoc Key Table}
      case Table of nil then nil
      [] K#V|Rest then
         if Key==K then V
         else 
            {Assoc Key Rest}
         end
      end
   end

end