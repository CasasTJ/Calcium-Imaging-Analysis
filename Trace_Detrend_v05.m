%% ============================================================
%   CaTrace_Detrend_GUI
%   Graphical User Interface for fluorescence trace correction
%
%   Description:
%   This script launches a GUI that allows the user to:
%   - Select an input .xlsx file from anywhere on their computer
%   - Set all correction parameters interactively
%   - Preview the raw data before running
%   - Choose where to save the corrected output .xlsx file
%
%   How to run:
%   Simply type CaTrace_Detrend_GUI in the MATLAB command window
%   or press F5 with this file open.
%
%   Author: Tomás Joaquin Casas - Astiz Lab
% ============================================================

function Trace_Detrend_v05()

%% --- Main figure window ---
fig = uifigure('Name', 'CaTrace Detrend', ...
    'Position', [100 100 780 620], ...
    'Resize', 'off');

%% --- Title ---
uilabel(fig, ...
    'Text', 'CaTrace Detrend', ...
    'Position', [20 575 400 35], ...
    'FontSize', 20, ...
    'FontWeight', 'bold');

uilabel(fig, ...
    'Text', 'Fluorescence trace correction for calcium imaging data', ...
    'Position', [20 555 500 20], ...
    'FontSize', 11, ...
    'FontColor', [0.4 0.4 0.4]);

%% ============================================================
%   PANEL 1 — FILE SELECTION
% ============================================================
panelFile = uipanel(fig, ...
    'Title', '1. File Selection', ...
    'Position', [20 470 740 75], ...
    'FontSize', 11, 'FontWeight', 'bold');

% Input file
uilabel(panelFile, 'Text', 'Input file (.xlsx):', ...
    'Position', [10 25 130 22]);
inputPathField = uieditfield(panelFile, 'text', ...
    'Position', [145 25 460 22], ...
    'Editable', 'off', ...
    'Placeholder', 'No file selected...');
uibutton(panelFile, 'Text', 'Browse', ...
    'Position', [615 24 100 24], ...
    'ButtonPushedFcn', @(~,~) browseInputFile());

%% ============================================================
%   PANEL 2 — PARAMETERS
% ============================================================
panelParams = uipanel(fig, ...
    'Title', '2. Parameters', ...
    'Position', [20 310 740 150], ...
    'FontSize', 11, 'FontWeight', 'bold');

% Row 1 — Acquisition
uilabel(panelParams, 'Text', 'Sampling frequency (Hz):', ...
    'Position', [10 100 180 22]);
fsField = uieditfield(panelParams, 'numeric', ...
    'Position', [195 100 80 22], 'Value', 1.01, ...
    'Limits', [0.01 1000]);

% Row 2 — Savitzky-Golay
uilabel(panelParams, 'Text', 'Savitzky-Golay order:', ...
    'Position', [10 65 160 22]);
sgOrderField = uieditfield(panelParams, 'numeric', ...
    'Position', [175 65 60 22], 'Value', 3, ...
    'Limits', [1 20], 'RoundFractionalValues', true);

uilabel(panelParams, 'Text', 'window (odd number):', ...
    'Position', [255 65 160 22]);
sgWindowField = uieditfield(panelParams, 'numeric', ...
    'Position', [415 65 60 22], 'Value', 11, ...
    'Limits', [3 999], 'RoundFractionalValues', true);

% Row 3 — Butterworth
uilabel(panelParams, 'Text', 'Butterworth order:', ...
    'Position', [10 30 150 22]);
hpOrderField = uieditfield(panelParams, 'numeric', ...
    'Position', [165 30 60 22], 'Value', 2, ...
    'Limits', [1 10], 'RoundFractionalValues', true);

uilabel(panelParams, 'Text', 'cutoff frequency (Hz):', ...
    'Position', [255 30 160 22]);
hpCutoffField = uieditfield(panelParams, 'numeric', ...
    'Position', [415 30 80 22], 'Value', 0.005, ...
    'Limits', [0.0001 0.5]);

% Row 4 — Baseline
uilabel(panelParams, 'Text', 'Baseline window (s):', ...
    'Position', [510 65 155 22]);
blWindowField = uieditfield(panelParams, 'numeric', ...
    'Position', [665 65 60 22], 'Value', 20, ...
    'Limits', [1 9999]);

uilabel(panelParams, 'Text', 'Baseline percentile:', ...
    'Position', [510 30 155 22]);
blPctField = uieditfield(panelParams, 'numeric', ...
    'Position', [665 30 60 22], 'Value', 20, ...
    'Limits', [1 99]);

%% ============================================================
%   PANEL 3 — DATA PREVIEW
% ============================================================
panelPreview = uipanel(fig, ...
    'Title', '3. Data Preview', ...
    'Position', [20 110 740 190], ...
    'FontSize', 11, 'FontWeight', 'bold');

previewTable = uitable(panelPreview, ...
    'Position', [10 10 720 155], ...
    'ColumnSortable', true);

%% ============================================================
%   STATUS BAR + BUTTONS
% ============================================================
statusLabel = uilabel(fig, ...
    'Text', 'Status: Waiting for input file...', ...
    'Position', [20 75 540 22], ...
    'FontColor', [0.4 0.4 0.4]);

uibutton(fig, 'Text', 'Load & Preview', ...
    'Position', [20 35 160 35], ...
    'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) loadAndPreview());

uibutton(fig, 'Text', '▶  Run Correction', ...
    'Position', [200 35 180 35], ...
    'FontSize', 11, ...
    'BackgroundColor', [0.18 0.55 0.34], ...
    'FontColor', 'white', ...
    'ButtonPushedFcn', @(~,~) runCorrection());

uibutton(fig, 'Text', 'Reset', ...
    'Position', [400 35 100 35], ...
    'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) resetGUI());

%% --- Shared variable to store loaded data ---
inputFilePath = '';
F_data        = [];

%% ============================================================
%   CALLBACK: Browse for input file
% ============================================================
    function browseInputFile()
        [file, path] = uigetfile('*.xlsx', 'Select input Excel file');
        if isequal(file, 0)
            return;
        end
        inputFilePath = fullfile(path, file);
        inputPathField.Value = inputFilePath;
        statusLabel.Text  = 'Status: File selected. Click "Load & Preview" to continue.';
        statusLabel.FontColor = [0.4 0.4 0.4];
    end

%% ============================================================
%   CALLBACK: Load data and show preview
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

            opts  = detectImportOptions(inputFilePath, 'PreserveVariableNames', true);
            opts  = setvartype(opts, 'double');
            T     = readtable(inputFilePath, opts);
            T(1,:) = [];
            F_data = table2array(T);
            F_data = F_data(~any(isnan(F_data), 2), :);

            [nFrames, nROIs] = size(F_data);

            % Build preview table (first 10 rows)
            roi_names  = "ROI_" + string(1:nROIs);
            previewData = array2table(F_data(1:min(10,nFrames), :), ...
                'VariableNames', roi_names);
            previewTable.Data = previewData;

            statusLabel.Text      = sprintf('Status: File loaded — %d frames, %d ROIs detected. Ready to run.', nFrames, nROIs);
            statusLabel.FontColor = [0.1 0.5 0.1];
        catch e
            statusLabel.Text      = ['Status: Error loading file — ' e.message];
            statusLabel.FontColor = [0.8 0.2 0.2];
        end
    end

%% ============================================================
%   CALLBACK: Run correction pipeline
% ============================================================
    function runCorrection()
        if isempty(F_data)
            statusLabel.Text      = 'Status: Please load a file first.';
            statusLabel.FontColor = [0.8 0.2 0.2];
            return;
        end

        % Read parameters from GUI
        Fs          = fsField.Value;
        sg_order    = sgOrderField.Value;
        sg_window   = sgWindowField.Value;
        hp_order    = hpOrderField.Value;
        hp_cutoff   = hpCutoffField.Value;
        bl_window   = blWindowField.Value;
        bl_pct      = blPctField.Value;

        % Validate Savitzky-Golay window is odd
        if mod(sg_window, 2) == 0
            sg_window = sg_window + 1;
            sgWindowField.Value = sg_window;
            statusLabel.Text = sprintf('Status: SG window adjusted to %d (must be odd). Running...', sg_window);
            drawnow;
        end

        [numFrames, numROIs] = size(F_data);

        try
            % --- Step 1: Savitzky-Golay smoothing ---
            statusLabel.Text      = 'Status: Applying Savitzky-Golay smoothing...';
            statusLabel.FontColor = [0.4 0.4 0.4];
            drawnow;
            F_smooth = sgolayfilt(F_data, sg_order, sg_window);
            F_smooth(~isfinite(F_smooth)) = 0;

            % --- Step 2: High-pass Butterworth filter ---
            statusLabel.Text = 'Status: Applying Butterworth filter...';
            drawnow;
            [b, a] = butter(hp_order, hp_cutoff, 'high');
            F_hp   = zeros(size(F_smooth));
            for roi = 1:numROIs
                x   = F_smooth(:, roi);
                bad = ~isfinite(x);
                if all(bad)
                    F_hp(:, roi) = zeros(size(x));
                    continue;
                elseif any(bad)
                    goodIdx = find(~bad);
                    x(bad)  = interp1(goodIdx, x(goodIdx), find(bad), 'linear', 'extrap');
                end
                if std(x) == 0
                    F_hp(:, roi) = zeros(size(x));
                    continue;
                end
                F_hp(:, roi) = filtfilt(b, a, x);
            end

            % --- Step 3: Local baseline subtraction ---
            statusLabel.Text = 'Status: Estimating and subtracting baseline...';
            drawnow;
            window_frames = round(bl_window * Fs);
            baseline      = zeros(size(F_hp));
            for roi = 1:numROIs
                x = F_hp(:, roi);
                for t = 1:numFrames
                    i1 = max(1, t - window_frames);
                    i2 = min(numFrames, t + window_frames);
                    baseline(t, roi) = prctile(x(i1:i2), bl_pct);
                end
            end
            F_corr = F_hp - baseline;

            % --- Step 4: Plot results ---
            statusLabel.Text = 'Status: Generating figures...';
            drawnow;
            for roi = 1:numROIs
                figure;
                yyaxis left
                plot(F_data(:, roi),  'LineWidth', 1.0, 'Color', [0.4 0.4 0.4])
                hold on
                plot(F_hp(:, roi),    'LineWidth', 1.5, 'Color', [0 0.45 0.74])
                ylabel('Original / Filtered (a.u.)')
                yyaxis right
                plot(F_corr(:, roi),  'LineWidth', 1.5, 'Color', [0.93 0.69 0.13])
                ylabel('F_{corr} (a.u.)')
                title(sprintf('ROI %d — Original | High-pass | Corrected', roi))
                xlabel('Frame')
                legend({'Original', 'Filtered', 'F_{corr}'}, 'Location', 'best')
                grid on
            end
            sgtitle('Calcium activity: Original vs Filtered vs Corrected');

            % --- Step 5: Ask user where to save output ---
            [outFile, outPath] = uiputfile('*.xlsx', 'Save corrected data as...');
            if isequal(outFile, 0)
                statusLabel.Text      = 'Status: Correction done but output was not saved (cancelled).';
                statusLabel.FontColor = [0.8 0.5 0.0];
                return;
            end
            output_file = fullfile(outPath, outFile);
            roi_names   = "ROI_" + string(1:numROIs);
            Tcorr       = array2table(F_corr, 'VariableNames', roi_names);
            writetable(Tcorr, output_file, 'Sheet', 1);

            statusLabel.Text      = ['Status: Done! File saved to ' output_file];
            statusLabel.FontColor = [0.1 0.5 0.1];

        catch e
            statusLabel.Text      = ['Status: Error during correction — ' e.message];
            statusLabel.FontColor = [0.8 0.2 0.2];
        end
    end

%% ============================================================
%   CALLBACK: Reset GUI
% ============================================================
    function resetGUI()
        inputFilePath         = '';
        F_data                = [];
        inputPathField.Value  = '';
        previewTable.Data     = {};
        statusLabel.Text      = 'Status: Waiting for input file...';
        statusLabel.FontColor = [0.4 0.4 0.4];
    end

end