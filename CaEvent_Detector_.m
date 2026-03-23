%% ============================================================
%   CaEvent_Detector_GUI
%   Graphical User Interface for calcium event detection
%
%   Description:
%   This script launches a GUI that allows the user to:
%   - Select a corrected fluorescence .xlsx file from anywhere
%   - Set all detection and classification parameters interactively
%   - Preview the raw data before running
%   - View a results summary (total, astrocyte, non-astrocyte events)
%   - Choose where to save the output .xlsx file
%
%   How to run:
%   Type CaEvent_Detector_GUI in the MATLAB command window
%   or press F5 with this file open.
%
%   Author: Tomás Joaquin Casas - Astiz Lab
% ============================================================

function CaEvent_Detector_()

%% --- Main figure window ---
fig = uifigure('Name', 'CaEvent Detector', ...
    'Position', [80 60 820 700], ...
    'Resize', 'off');

%% --- Title ---
uilabel(fig, ...
    'Text', 'CaEvent Detector', ...
    'Position', [20 655 400 35], ...
    'FontSize', 20, 'FontWeight', 'bold');

uilabel(fig, ...
    'Text', 'Calcium event detection and characterization', ...
    'Position', [20 635 500 20], ...
    'FontSize', 11, 'FontColor', [0.4 0.4 0.4]);

%% ============================================================
%   PANEL 1 — FILE SELECTION
% ============================================================
panelFile = uipanel(fig, ...
    'Title', '1. File Selection', ...
    'Position', [20 555 780 70], ...
    'FontSize', 11, 'FontWeight', 'bold');

uilabel(panelFile, 'Text', 'Input file (.xlsx):', ...
    'Position', [10 22 130 22]);
inputPathField = uieditfield(panelFile, 'text', ...
    'Position', [145 22 500 22], ...
    'Editable', 'off', ...
    'Placeholder', 'No file selected...');
uibutton(panelFile, 'Text', 'Browse', ...
    'Position', [655 21 105 24], ...
    'ButtonPushedFcn', @(~,~) browseInputFile());

%% ============================================================
%   PANEL 2 — DETECTION PARAMETERS
% ============================================================
panelParams = uipanel(fig, ...
    'Title', '2. Detection Parameters', ...
    'Position', [20 390 780 155], ...
    'FontSize', 11, 'FontWeight', 'bold');

% Row 1 — Baseline & threshold
uilabel(panelParams, 'Text', 'Baseline percentile:', ...
    'Position', [10 105 150 22]);
blPctField = uieditfield(panelParams, 'numeric', ...
    'Position', [165 105 70 22], 'Value', 20, ...
    'Limits', [1 99]);

uilabel(panelParams, 'Text', 'Threshold multiplier (x std):', ...
    'Position', [270 105 200 22]);
thrMultField = uieditfield(panelParams, 'numeric', ...
    'Position', [475 105 70 22], 'Value', 3, ...
    'Limits', [0.5 20]);

% Row 2 — Amplitude filter & bin size
uilabel(panelParams, 'Text', 'Min. amplitude filter:', ...
    'Position', [10 68 155 22]);
minAmpField = uieditfield(panelParams, 'numeric', ...
    'Position', [170 68 70 22], 'Value', 0.03, ...
    'Limits', [0 100]);

uilabel(panelParams, 'Text', 'Raster bin size (frames):', ...
    'Position', [270 68 185 22]);
binSizeField = uieditfield(panelParams, 'numeric', ...
    'Position', [460 68 70 22], 'Value', 10, ...
    'Limits', [1 9999], 'RoundFractionalValues', true);

% Row 3 — Astrocyte classification
uilabel(panelParams, 'Text', 'Astrocyte classification thresholds:', ...
    'Position', [10 30 240 22], 'FontWeight', 'bold');

uilabel(panelParams, 'Text', 'Min. duration (frames):', ...
    'Position', [10 8 165 22]);
astroDurField = uieditfield(panelParams, 'numeric', ...
    'Position', [180 8 70 22], 'Value', 10, ...
    'Limits', [1 9999], 'RoundFractionalValues', true);

uilabel(panelParams, 'Text', 'Min. amplitude:', ...
    'Position', [270 8 120 22]);
astroAmpField = uieditfield(panelParams, 'numeric', ...
    'Position', [395 8 70 22], 'Value', 0.05, ...
    'Limits', [0 100]);

uilabel(panelParams, 'Text', '+ rise time < decay time', ...
    'Position', [490 8 200 22], 'FontColor', [0.4 0.4 0.4]);

%% ============================================================
%   PANEL 3 — DATA PREVIEW
% ============================================================
panelPreview = uipanel(fig, ...
    'Title', '3. Data Preview (first 10 rows)', ...
    'Position', [20 210 780 170], ...
    'FontSize', 11, 'FontWeight', 'bold');

previewTable = uitable(panelPreview, ...
    'Position', [10 10 760 135], ...
    'ColumnSortable', true);

%% ============================================================
%   PANEL 4 — RESULTS SUMMARY
% ============================================================
panelResults = uipanel(fig, ...
    'Title', '4. Results Summary', ...
    'Position', [20 110 780 90], ...
    'FontSize', 11, 'FontWeight', 'bold');

totalLabel  = uilabel(panelResults, 'Text', 'Total events detected: —', ...
    'Position', [10 45 300 22], 'FontSize', 11);
astroLabel  = uilabel(panelResults, 'Text', 'Astrocyte events: —', ...
    'Position', [10 20 300 22], 'FontSize', 11, 'FontColor', [0.18 0.55 0.34]);
nonAstroLabel = uilabel(panelResults, 'Text', 'Non-astrocyte events: —', ...
    'Position', [320 20 300 22], 'FontSize', 11, 'FontColor', [0.74 0.35 0.0]);
roiLabel    = uilabel(panelResults, 'Text', 'ROIs processed: —', ...
    'Position', [320 45 300 22], 'FontSize', 11);

%% ============================================================
%   STATUS BAR + BUTTONS
% ============================================================
statusLabel = uilabel(fig, ...
    'Text', 'Status: Waiting for input file...', ...
    'Position', [20 75 580 22], ...
    'FontColor', [0.4 0.4 0.4]);

uibutton(fig, 'Text', 'Load & Preview', ...
    'Position', [20 35 160 35], 'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) loadAndPreview());

uibutton(fig, 'Text', '▶  Run Detection', ...
    'Position', [200 35 180 35], 'FontSize', 11, ...
    'BackgroundColor', [0.18 0.55 0.34], ...
    'FontColor', 'white', ...
    'ButtonPushedFcn', @(~,~) runDetection());

uibutton(fig, 'Text', 'Reset', ...
    'Position', [400 35 100 35], 'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) resetGUI());

%% --- Shared variables ---
inputFilePath = '';
roiData       = [];
roiNames      = {};
numFrames     = 0;
numROIs       = 0;

%% ============================================================
%   CALLBACK: Browse for input file
% ============================================================
    function browseInputFile()
        [file, path] = uigetfile('*.xlsx', 'Select corrected data file');
        if isequal(file, 0), return; end
        inputFilePath        = fullfile(path, file);
        inputPathField.Value = inputFilePath;
        statusLabel.Text     = 'Status: File selected. Click "Load & Preview" to continue.';
        statusLabel.FontColor = [0.4 0.4 0.4];
    end

%% ============================================================
%   CALLBACK: Load and preview data
% ============================================================
    function loadAndPreview()
        if isempty(inputFilePath)
            statusLabel.Text      = 'Status: Please select an input file first.';
            statusLabel.FontColor = [0.8 0.2 0.2];
            return;
        end
        try
            statusLabel.Text      = 'Status: Loading file...';
            statusLabel.FontColor = [0.4 0.4 0.4];
            drawnow;

            opts = detectImportOptions(inputFilePath);
            opts = setvartype(opts, 'double');
            data = readtable(inputFilePath, opts);

            roiNames  = data.Properties.VariableNames(2:end);
            roiData   = data{:, 2:end};
            numROIs   = size(roiData, 2);
            numFrames = size(roiData, 1);

            % Preview first 10 rows
            previewData = array2table(roiData(1:min(10,numFrames), :), ...
                'VariableNames', roiNames);
            previewTable.Data = previewData;

            statusLabel.Text      = sprintf('Status: Loaded — %d frames, %d ROIs. Ready to run.', numFrames, numROIs);
            statusLabel.FontColor = [0.1 0.5 0.1];
        catch e
            statusLabel.Text      = ['Status: Error — ' e.message];
            statusLabel.FontColor = [0.8 0.2 0.2];
        end
    end

%% ============================================================
%   CALLBACK: Run detection pipeline
% ============================================================
    function runDetection()
        if isempty(roiData)
            statusLabel.Text      = 'Status: Please load a file first.';
            statusLabel.FontColor = [0.8 0.2 0.2];
            return;
        end

        % Read parameters
        bl_pct      = blPctField.Value;
        thr_mult    = thrMultField.Value;
        min_amp     = minAmpField.Value;
        bin_size    = binSizeField.Value;
        astro_dur   = astroDurField.Value;
        astro_amp   = astroAmpField.Value;

        try
            Events       = table();
            eventCount   = 0;
            rasterMatrix = zeros(numROIs, numFrames);

            statusLabel.Text      = 'Status: Detecting events...';
            statusLabel.FontColor = [0.4 0.4 0.4];
            drawnow;

            for r = 1:numROIs
                signal  = roiData(:, r);
                roiName = roiNames{r};

                % Baseline
                baseline = prctile(signal, bl_pct);
                stdBase  = std(signal(signal <= baseline));
                thr      = baseline + thr_mult * stdBase;

                % ROI AUC
                roiSignal = signal - baseline;
                roiSignal(roiSignal < 0) = 0;
                roiAUC = trapz(roiSignal);

                % Detection loop
                inEvent  = false;
                startIdx = NaN;
                peakIdx  = NaN;
                peakVal  = -Inf;

                for i = 1:numFrames
                    val = signal(i);

                    if ~inEvent && val > thr
                        inEvent  = true;
                        startIdx = i;
                        peakIdx  = i;
                        peakVal  = val;
                    end

                    if inEvent
                        if val > peakVal
                            peakVal = val;
                            peakIdx = i;
                        end

                        if val <= thr || i == numFrames
                            endIdx    = i;
                            riseTime  = peakIdx - startIdx;
                            decayTime = endIdx  - peakIdx;
                            width     = riseTime + decayTime;
                            duration  = endIdx  - startIdx;
                            amplitude = peakVal - baseline;

                            if amplitude < min_amp
                                inEvent = false;
                                continue
                            end

                            eventSignal = signal(startIdx:endIdx) - baseline;
                            eventSignal(eventSignal < 0) = 0;
                            eventAUC = trapz(eventSignal);

                            if duration > astro_dur && ...
                               amplitude > astro_amp && ...
                               riseTime < decayTime
                                eventType = "Astrocyte";
                            else
                                eventType = "Non-astrocyte";
                            end

                            eventCount = eventCount + 1;
                            Events(eventCount, :) = table( ...
                                string(roiName), ...
                                startIdx, peakIdx, endIdx, ...
                                amplitude, duration, riseTime, decayTime, width, ...
                                eventAUC, roiAUC, eventType, ...
                                'VariableNames', ...
                                {'ROI','StartFrame','PeakFrame','EndFrame', ...
                                 'Amplitude','Duration','Rise','Decay','Width', ...
                                 'EventAUC','ROI_AUC','Type'});

                            rasterMatrix(r, peakIdx) = 1;
                            inEvent = false;
                        end
                    end
                end
            end

            % Build raster tables
            statusLabel.Text = 'Status: Building raster tables...';
            drawnow;

            rasterTable = array2table(rasterMatrix', 'VariableNames', roiNames(:)');
            rasterTable = [table((1:numFrames)', 'VariableNames', {'Frame'}), rasterTable];

            numBins      = ceil(numFrames / bin_size);
            binnedMatrix = zeros(numROIs, numBins);
            for b = 1:numBins
                f1 = (b-1)*bin_size + 1;
                f2 = min(b*bin_size, numFrames);
                binnedMatrix(:,b) = any(rasterMatrix(:, f1:f2), 2);
            end
            binLabels = cell(numBins,1);
            for b = 1:numBins
                f1 = (b-1)*bin_size + 1;
                f2 = min(b*bin_size, numFrames);
                binLabels{b} = sprintf('%d-%d', f1, f2);
            end
            binnedTable = array2table(binnedMatrix', 'VariableNames', roiNames(:)');
            binnedTable = [table(binLabels, 'VariableNames', {'Bin_Frames'}), binnedTable];

            % Update summary panel
            nAstro    = sum(Events.Type == "Astrocyte");
            nNonAstro = sum(Events.Type == "Non-astrocyte");
            totalLabel.Text    = sprintf('Total events detected: %d', eventCount);
            astroLabel.Text    = sprintf('Astrocyte events: %d', nAstro);
            nonAstroLabel.Text = sprintf('Non-astrocyte events: %d', nNonAstro);
            roiLabel.Text      = sprintf('ROIs processed: %d', numROIs);

            % Save output
            [outFile, outPath] = uiputfile('*.xlsx', 'Save results as...');
            if isequal(outFile, 0)
                statusLabel.Text      = 'Status: Detection done but output not saved (cancelled).';
                statusLabel.FontColor = [0.8 0.5 0.0];
                return;
            end
            output_file = fullfile(outPath, outFile);
            writetable(Events,      output_file, 'Sheet', 'Events');
            writetable(rasterTable, output_file, 'Sheet', 'Raster');
            writetable(binnedTable, output_file, 'Sheet', 'Raster_Binned');

            statusLabel.Text      = ['Status: Done! Results saved to ' output_file];
            statusLabel.FontColor = [0.1 0.5 0.1];

        catch e
            statusLabel.Text      = ['Status: Error — ' e.message];
            statusLabel.FontColor = [0.8 0.2 0.2];
        end
    end

%% ============================================================
%   CALLBACK: Reset GUI
% ============================================================
    function resetGUI()
        inputFilePath        = '';
        roiData              = [];
        roiNames             = {};
        numFrames            = 0;
        numROIs              = 0;
        inputPathField.Value = '';
        previewTable.Data    = {};
        totalLabel.Text      = 'Total events detected: —';
        astroLabel.Text      = 'Astrocyte events: —';
        nonAstroLabel.Text   = 'Non-astrocyte events: —';
        roiLabel.Text        = 'ROIs processed: —';
        statusLabel.Text     = 'Status: Waiting for input file...';
        statusLabel.FontColor = [0.4 0.4 0.4];
    end

end