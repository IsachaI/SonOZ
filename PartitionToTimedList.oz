 functor
 import
    Project2025
    System
    Property
 export 
    partitionToTimedList: PartitionToTimedList
 define
 
    % Translate a note to the extended notation.
    fun {NoteToExtended Note}
        case Note
        of nil then nil 
        [] note(...) then Note
        [] silence(duration: _) then Note
        [] silence then silence(duration:1.0)
        [] Name#Octave then note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
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

    %Tune = [b b c5 d5 d5 c5 b a g g a b]
    %End1 = [stretch(factor:1.5 [b]) stretch(factor:0.5 [a]) stretch(factor:2.0 [a])]
    %End2 = [stretch(factor:1.5 [a]) stretch(factor:0.5 [g]) stretch(factor:2.0 [g])]
    %Interlude = [a a b g a stretch(factor:0.5 [b c5])
    %                 b g a stretch(factor:0.5 [b c5])
    %             b a g a stretch(factor:2.0 [d]) ]
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun {RepeatNote N A}
      C = {NewCell nil}
      proc {Loop I}
         if I > 0 then
            C := A | @C
            {Loop I - 1}
         end
      end
   in
      {Loop N}
      {Reverse @C}
   end
   
   
    
fun {PartitionToTimedList Partition}
   case Partition
   of nil then nil
   [] H|T then
      FlatHead =  case H
         of note(...) then [H]  
         [] silence(duration: _) then [H]
         [] silence then [{NoteToExtended H}] 
         [] _|_ then 
            [{Map H NoteToExtended}]  
         [] duration(seconds:D P) then
           
            Flat = {PartitionToTimedList P}
         in
            {ScalePartition D Flat}
         [] stretch(factor:F P) then
            Flat = {PartitionToTimedList P}
         in
            {Map Flat
             fun {$ E}
                {ScaleElement E F}
             end}
         [] drone(note:N amount:A) then
            One = case N of _|_ then [{Map N NoteToExtended}]
                           [] _ then [{NoteToExtended N}]
                  end
         in
            {RepeatNote A One}
         [] mute(amount:A) then
            {RepeatNote A [silence(duration:1.0)]}
            
         [] transpose(semitones:S P) then
            Flat = {PartitionToTimedList P}
         in
            {Map Flat
             fun {$ E}
                case E
                of note(...) then {TransposeNote E S}
                [] silence(duration:_) then E
                [] Chord then {Map Chord fun {$ N} {TransposeNote N S} end}
                end
             end}   
         [] _ then [{NoteToExtended H}]
         end
   in
      {Append FlatHead {PartitionToTimedList T}}
   end
end

fun {GetDuration Element}
   case Element
   of note(duration:D ...) then D
   [] silence(duration:D) then D
   [] Notes then
      % Accord : on prend la durée la plus longue
      {FoldL Notes
         fun {$ Max N}
            D = {GetDuration N}
         in
            if D > Max then D else Max end
         end 0.0}
   end
end

fun {TotalDuration Partition}
   case Partition
   of nil then 0.0
   [] H|T then
      {GetDuration H} + {TotalDuration T}
   end
end

fun {ScaleElement Element Factor}
   case Element
   of note(duration:D name:N octave:O sharp:S instrument:I) then
      note(duration:D * Factor name:N octave:O sharp:S instrument:I)
   [] silence(duration:D) then
      silence(duration:D * Factor)
   [] Notes then
      {Map Notes 
         fun {$ N}
            {ScaleElement N Factor}
         end}
   end
end

fun {ScalePartition DurationSeconds Partition}
   Total = {TotalDuration Partition}
   Scaling = DurationSeconds / Total
in
   {Map Partition
      fun {$ E}
         {ScaleElement E Scaling}
      end}
end


fun {TransposeNote Note Semitones}
   SemitoneTable = [c#false c#true d#false d#true e#false f#false f#true g#false g#true a#false a#true b#false]
in
   case Note
   of note(name:N octave:O sharp:S duration:D instrument:I) then
      Index =  case N#S
         of c#false then 0
         [] c#true then 1
         [] d#false then 2
         [] d#true then 3
         [] e#false then 4
         [] f#false then 5
         [] f#true then 6
         [] g#false then 7
         [] g#true then 8
         [] a#false then 9
         [] a#true then 10
         [] b#false then 11
         end

      NewIndex = Index + Semitones
      FinalIndex = NewIndex mod 12
      NewOctave = O + (NewIndex div 12)

      NewName#NewSharp = {List.nth SemitoneTable FinalIndex + 1}
   in
      note(name:NewName
           octave:NewOctave
           sharp:NewSharp
           duration:D
           instrument:I)

   [] silence(duration:D) then
      silence(duration:D)

   [] Notes then
      {Map Notes fun {$ N} {TransposeNote N Semitones} end}
   end
end

end
