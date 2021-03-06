function varargout = LoadSortData_BATCH(varargin)
% LOADSORTDATA_BATCH M-file for LoadSortData_BATCH.fig
% Last Modified by GUIDE v2.5 24-Sep-2007 15:39:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LoadSortData_BATCH_OpeningFcn, ...
                   'gui_OutputFcn',  @LoadSortData_BATCH_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before LoadSortData_BATCH is made visible.
function LoadSortData_BATCH_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LoadSortData_BATCH (see VARARGIN)

% Choose default command line output for LoadSortData_BATCH
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LoadSortData_BATCH wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LoadSortData_BATCH_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_BatchFileName_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BatchFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_BatchFileName as text
%        str2double(get(hObject,'String')) returns contents of edit_BatchFileName as a double


% --- Executes during object creation, after setting all properties.
function edit_BatchFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BatchFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in LoadButton.
function LoadButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  
%     dfltDir = 'Z:\Users\Aihua\SpikeSorting\Batch';% Default data directory
    dfltDir = 'C:\Aihua\SpikeSorting\Batch';% Default data directory    
    dfltSuffix = '*.m';      % Default file type.
    cd(dfltDir);

    % Locate the batch file and check if anything was chosen.
    [batchFileName, batchPath] = uigetfile(dfltSuffix, 'Choose Batch File');
    if (batchFileName == 0)
        return;
    end
    set(handles.edit_BatchFileName, 'String', [batchPath, batchFileName]);

    % Use textread to grab the path and filename of all files to be processed.
    [handles.filePath, handles.fileName, handles.ChannelWaveMark] = textread([batchPath, batchFileName], '%s%s%f%*[^\n]', 'commentstyle', 'matlab');
    set(handles.FileList,'String',[handles.fileName]);
    
    
    % Store the monkey's name.
    handles.monkeyName = batchPath(13:length(batchPath) - 1);
    guidata(hObject, handles);

% --- Executes on button press in StartButton.
function StartButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %Make sure these variables are clear
    clear global CHAN1;
    clear global CHAN32;
    clear global spsData2;
    
    %Clear the FileList
    set(handles.FileList,'Value',1);
    set(handles.FileList,'String','');
    
    %buff=fopen('Z:\Users\Aihua\SpikeSorting\LoadSortData_BATCH.log','w');
    
    for (i=1:length(handles.fileName))
        fileList=get(handles.FileList,'String');
        listLength=length(fileList);
        
        % Generate .smr filpath and filename.
        x = find(handles.filePath{i} == '\');
        if isempty(strfind(handles.filePath{i}, 'MOOG'))
            handles.smrFilePath = ['Z:\Data\', handles.filePath{i}(x(3)+1 : x(4) - 1), '\Analysis\Smr_Sorted\'];
        else
            handles.smrFilePath = ['Z:\Data\MOOG\', handles.filePath{i}(x(3)+1 : x(4) - 1), '\Analysis\Smr_Sorted\'];
        end
        
        handles.smrFileName=[handles.fileName{i}(1:length(handles.fileName{i})-4),'.smr'];
        handles.dataFileName=handles.smrFileName;
        
        %Add the file being processed to the list
        fileList{listLength+1}=['Analyzing --',handles.smrFilePath, handles.smrFileName,'...........'];
        set(handles.FileList,'String',fileList);
        set(handles.FileList,'Value',listLength+1);
        
        %Call all the processing functions
        disp('Loading spike2 sorted data');
        handles=LoadSpike2SortedData(handles,i);
        
        %Go to the next file if there was a problem opeing the file.
        if(handles.spike2file<0)
            %Show that the file was bad or corrupt
            fileList{ListLength+1}=[fileList{listLength+1},'Bad File'];

            %Updata the file list
            set(handles.FileList,'String',fileList);
            set(handles.FileList,'Value',listLength+1);
            
            %write out string to log file to keep record of results
            fprintf(buff, '%s \n', fileList{listLength + 1});
            continue;
        end

%         %Close the .smr file        
%         fclose(handles.spike2file);
%         disp('Spike2 data file closed');
%     
%         %Export spsData2
%         global sps2Data2
%         slashIndex = findstr(handles.smrFilePath, '\');
%         monkeyName =handles.smrFilePath(slashIndex(3)+1:slashIndex(4)-1);
%         % OutFileName=['Z:\Data\Moog\', monkeyName, '\Analysis\SortedSpikes2\', handles.dataFileName(1:length(handles.dataFileName) - 3), 'mat']; 
%         OutFileName=['C:\Aihua\SpikeSorting\Data\',handles.dataFileName(1:length(handles.dataFileName) - 3), 'mat'] 
%         eval(['save ', OutFileName, ' spsData2']);
        
        % Clear all data channels.
        clear global CHAN1;
        clear global CHAN32;
        clear global spsData2;
        
        % Show that the file is done being processed.
        fileList{listLength + 1} = [fileList{listLength + 1}, 'Finished'];
        
        % Update the file list.
        set(handles.FileList, 'String', fileList);
        set(handles.FileList, 'Value', listLength + 1);
        
%         % write out string to log file to keep record of results
%         fprintf(buff, '%s \n', fileList{listLength + 1});        
    end
%     fclose(buff);
    
    % Indicate that everything is finished.
    fl = get(handles.FileList, 'String');
    fl{length(fl) + 1} = 'Done';
    set(handles.FileList, 'String', fl);
    set(handles.FileList, 'Value', length(fl));
    
    guidata(hObject, handles);    
  
% ----------------------------------------------------------------------------
%   Loads spike2 data from a file and processes it.
% ----------------------------------------------------------------------------
function handles = LoadSpike2SortedData(handles, dumdex)

    % Open up the Spike2 data file.
    handles.spike2file=fopen([handles.smrFilePath, handles.smrFileName]);
    if (handles.spike2file >= 0)
        disp('File opened successfully');
    else
        disp('Could not open smr file.');
        return;
    end
    
    % Load ADCMarker (WaveMark) into memory.
    global CHAN3;
    [CHAN3, CHAN3header]=SONGetADCMarkerChannel(handles.spike2file,handles.ChannelWaveMark(dumdex));
%     ChannelWaveMark=3;
%     [CHAN3, CHAN3header]=SONGetADCMarkerChannel(handles.spike2file,ChannelWaveMark);

    
    %Get the Markers of the sorted neurons
    Markers=double(CHAN3.markers(:,1));
    [NeuronID,SpikeNumber]=munique(Markers)
    
%     [pc, zscores, pcvars] = princomp(double(CHAN3.adc));
%     cumsum(pcvars./sum(pcvars) * 100);
%     figure;gscatter(zscores(:,1),zscores(:,2),Markers,'krgbcym','.******');
%     xlabel('PC1');ylabel('PC2');
%     title('Principal Component Scatter Plot with Colored Clusters');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %reject some neuron if the firing rate is too low
    MaxSpikeNumber=max(SpikeNumber);
    k=0;
    for i=1:size(NeuronID,1)
        if NeuronID(i)>0
            if SpikeNumber(i)>0.01*MaxSpikeNumber
                k=k+1;
                SelectNeuronID(k)=NeuronID(i);        
            end
        end
    end

    %find the timings of the SelectNeuronID
    for i=1:length(SelectNeuronID)
        Index=find(Markers(:,1)==SelectNeuronID(i));
        Neuron(i).SpikeTiming=CHAN3.timings(Index);
        %spsData2(i).SpikeTiming=CHAN3.timings(Index);
        clear Index;
    end

    %Convert to tempo format
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Load Event channel 32 into memory
    global CHAN32;
    [CHAN32 CHAN32Header]=SONGetMarkerChannel(handles.spike2file,32);
    
    index = [];
    for (i = 1:length(CHAN32.timings))
        % If we find a stimuls start code, then we look to see if we find
        % a success code before we get to another start code.
        if(real(CHAN32.markers(i,1)) == 4)
            j = i + 1;
            while (j <= length(CHAN32.timings) & real(CHAN32.markers(j,1)) ~= 4)
                if (real(CHAN32.markers(j,1)) == 12)
                    index = [index, i];
                    break;
                else
                    j = j + 1;
                end
            end
            i = j;
        end
    end

%     global spsData2;
    % Stuff the spsData2 struct array with information about each successfull trial.
    for k=1:length(SelectNeuronID)
        PreEventBuffer=1;
        PostEventBuffer=4;
        spsData2(k).sampleRate = 25000;
        spsData2(k).prebuffer = round(PreEventBuffer * 25000);
        spsData2(k).postbuffer = round(PostEventBuffer * 25000);
        
        for (i = 1:length(index))   
            % This is basically descriptive data about the spike area analyzed.   
            spsData2(k).spikeInfo(i).startCodeTime = CHAN32.timings(index(i))*spsData2(k).sampleRate;     
            spsData2(k).spikeInfo(i).startTime = spsData2(k).spikeInfo(i).startCodeTime - spsData2(k).prebuffer + 1;    
            spsData2(k).spikeInfo(i).endTime = spsData2(k).spikeInfo(i).startCodeTime + spsData2(k).postbuffer;
            
            % Store all the event codes for later reference. 
            binCount = (spsData2(k).postbuffer + spsData2(k).prebuffer) /spsData2(k).sampleRate * 1000;
            slotsperbin = (spsData2(k).postbuffer + spsData2(k).prebuffer) / binCount;
            spsData2(k).spikeInfo(i).eventCodes = zeros(1, binCount);
            mrstart = spsData2(k).spikeInfo(i).startTime;
            mrend = spsData2(k).spikeInfo(i).endTime;
            mrsuckass = spsData2(k).sampleRate*[CHAN32.timings];      
            mrstupid = find(mrsuckass >= mrstart & mrsuckass <= mrend);
            
            a = [CHAN32.timings(mrstupid)]*spsData2(k).sampleRate;
            CHAN32markers=real(CHAN32.markers(:,1));
            spsData2(k).spikeInfo(i).eventCodes([ceil((a - spsData2(k).spikeInfo(i).startTime + 1) / 25)]) =CHAN32markers(mrstupid);
            
            %Find spike times of each trial
            clear mrsuckass;mrsuckass=Neuron(k).SpikeTiming'*spsData2(k).sampleRate;
            clear mrstupid;mrstupid=find(mrsuckass >= mrstart & mrsuckass <= mrend);
            spsData2(k).spikeInfo(i).SpikeTimes=mrsuckass(mrstupid);    
        end % End for (i = 1:length(index))    
    end
     
    %Set the sorted spikes output file
    slashIndex = findstr(handles.smrFilePath, '\');
    monkeyName =handles.smrFilePath(slashIndex(3)+1:slashIndex(4)-1);
%     OutFileName=['Z:\Data\Moog\', monkeyName, '\Analysis\SortedSpikes2\', handles.dataFileName(1:length(handles.dataFileName) - 3), 'mat']; 
    OutFileName=['C:\Aihua\SpikeSorting\Data\',handles.dataFileName(1:length(handles.dataFileName) - 3), 'mat'] 
    eval(['save ', OutFileName, ' spsData2']);
    
    %Close the .smr file
    fclose(handles.spike2file);
    disp('Spike2 data file closed');
    
    return;


% --- Executes on selection change in FileList.
function FileList_Callback(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FileList = get(hObject,'String');

% Hints: contents = get(hObject,'String') returns FileList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FileList

% --- Executes during object creation, after setting all properties.
function FileList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on key press over FileList with no controls selected.
function FileList_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


