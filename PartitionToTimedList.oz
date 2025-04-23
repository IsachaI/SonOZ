 
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
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
end