function ColorLabPicker
%-----------------------------------------------------------
% Features:
%   1. Load an image.
%   2. Click one point to inspect RGB, HSV, XYZ, and CIELAB.
%   3. Click two points to calculate color difference.
%   4. Select an ROI and calculate mean color values.
%   5. Export measured results to CSV.
%-----------------------------------------------------------
    close all;
    clc;

    app.rgbImage = [];
    app.rgbDouble = [];
    app.labImage = [];
    app.xyzImage = [];
    app.hsvImage = [];
    app.imagePath = "";
    app.results = {};
    app.pointHandles = gobjects(0);

    app.fig = figure( ...
        'Name', 'CIELAB Color Analysis Tool', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'figure', ...
        'Color', [0.96 0.96 0.96], ...
        'Units', 'normalized', ...
        'Position', [0.08 0.08 0.84 0.82]);

    app.ax = axes( ...
        'Parent', app.fig, ...
        'Units', 'normalized', ...
        'Position', [0.05 0.18 0.58 0.76]);
    axis(app.ax, 'off');
    title(app.ax, 'Load an image to start');

    app.panel = uipanel( ...
        'Parent', app.fig, ...
        'Title', 'Controls', ...
        'Units', 'normalized', ...
        'Position', [0.66 0.52 0.30 0.42]);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'Load Image', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.84 0.40 0.10], ...
        'Callback', @loadImage);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'Clear Marks', ...
        'Units', 'normalized', ...
        'Position', [0.54 0.84 0.40 0.10], ...
        'Callback', @clearMarks);

    uicontrol(app.panel, ...
        'Style', 'text', ...
        'String', 'Delta E formula', ...
        'HorizontalAlignment', 'left', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.70 0.42 0.07]);

    app.deltaPopup = uicontrol(app.panel, ...
        'Style', 'popupmenu', ...
        'String', {'CIE76', 'CIE94', 'CIEDE2000'}, ...
        'Units', 'normalized', ...
        'Position', [0.54 0.71 0.40 0.08]);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'Single Point', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.55 0.88 0.10], ...
        'Callback', @singlePoint);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'Two Point Delta E', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.42 0.88 0.10], ...
        'Callback', @twoPointDeltaE);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'ROI Mean Color', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.29 0.88 0.10], ...
        'Callback', @roiMeanColor);

    uicontrol(app.panel, ...
        'Style', 'pushbutton', ...
        'String', 'Export CSV', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.16 0.88 0.10], ...
        'Callback', @exportCsv);

    uicontrol(app.panel, ...
        'Style', 'text', ...
        'String', 'Tip: click on the image after choosing a function.', ...
        'HorizontalAlignment', 'left', ...
        'Units', 'normalized', ...
        'Position', [0.06 0.03 0.88 0.08]);

    app.resultBox = uicontrol(app.fig, ...
        'Style', 'edit', ...
        'Max', 10, ...
        'Min', 0, ...
        'Enable', 'inactive', ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'Consolas', ...
        'Units', 'normalized', ...
        'Position', [0.66 0.18 0.30 0.30], ...
        'String', 'Load an image to start.');

    app.table = uitable(app.fig, ...
        'Units', 'normalized', ...
        'Position', [0.05 0.03 0.91 0.11], ...
        'ColumnName', {'Type', 'X', 'Y', 'R', 'G', 'B', 'L*', 'a*', 'b*', 'DeltaE'}, ...
        'ColumnWidth', {110, 55, 55, 55, 55, 55, 65, 65, 65, 75}, ...
        'Data', {});

    guidata(app.fig, app);

    function loadImage(~, ~)
        app = guidata(gcbf);

        [fileName, folderName] = uigetfile( ...
            {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff', 'Image Files'}, ...
            'Select an image');

        if isequal(fileName, 0)
            return;
        end

        app.imagePath = string(fullfile(folderName, fileName));
        app.rgbImage = imread(app.imagePath);

        if size(app.rgbImage, 3) == 1
            app.rgbImage = repmat(app.rgbImage, [1 1 3]);
        end

        if size(app.rgbImage, 3) > 3
            app.rgbImage = app.rgbImage(:, :, 1:3);
        end

        app.rgbDouble = im2double(app.rgbImage);
        app.labImage = rgb2lab(app.rgbDouble);
        app.xyzImage = rgb2xyz(app.rgbDouble);
        app.hsvImage = rgb2hsv(app.rgbDouble);
        app.results = {};

        imshow(app.rgbImage, 'Parent', app.ax);
        title(app.ax, sprintf('Image: %s', fileName), 'Interpreter', 'none');
        app.pointHandles = gobjects(0);
        set(app.resultBox, 'String', 'Image loaded. Choose a function.');
        set(app.table, 'Data', app.results);

        guidata(app.fig, app);
    end

    function singlePoint(~, ~)
        app = guidata(gcbf);
        if ~hasImage(app)
            return;
        end

        set(app.resultBox, 'String', 'Click one point on the image.');
        [x, y] = pickPoint(app);
        sample = samplePoint(app, x, y);
        addPointMark(app, x, y, 'r', '1');

        resultText = formatSampleText("Single Point", sample);
        set(app.resultBox, 'String', resultText);

        app.results(end + 1, :) = makeResultRow("Single", x, y, sample.rgb, sample.lab, NaN);
        set(app.table, 'Data', app.results);
        guidata(app.fig, app);
    end

    function twoPointDeltaE(~, ~)
        app = guidata(gcbf);
        if ~hasImage(app)
            return;
        end

        set(app.resultBox, 'String', 'Click point 1, then point 2.');
        [x, y] = pickPoints(app, 2);

        sampleOne = samplePoint(app, x(1), y(1));
        sampleTwo = samplePoint(app, x(2), y(2));
        formulaName = selectedDeltaFormula(app);
        deltaValue = calculateDeltaE(sampleOne.lab, sampleTwo.lab, formulaName);

        addPointMark(app, x(1), y(1), 'r', '1');
        addPointMark(app, x(2), y(2), 'b', '2');
        line(app.ax, x, y, 'Color', 'y', 'LineWidth', 2);

        resultText = sprintf([ ...
            '%s\n\n' ...
            'Point 1\n%s\n\n' ...
            'Point 2\n%s\n\n' ...
            '%s = %.4f'], ...
            'Two Point Color Difference', ...
            formatSampleText("", sampleOne), ...
            formatSampleText("", sampleTwo), ...
            formulaName, deltaValue);

        set(app.resultBox, 'String', resultText);

        app.results(end + 1, :) = makeResultRow("Delta P1", x(1), y(1), sampleOne.rgb, sampleOne.lab, deltaValue);
        app.results(end + 1, :) = makeResultRow("Delta P2", x(2), y(2), sampleTwo.rgb, sampleTwo.lab, deltaValue);
        set(app.table, 'Data', app.results);
        guidata(app.fig, app);
    end

    function roiMeanColor(~, ~)
        app = guidata(gcbf);
        if ~hasImage(app)
            return;
        end

        set(app.resultBox, 'String', 'Drag a rectangle on the image.');
        rect = round(getrect(app.ax));

        if isempty(rect) || rect(3) <= 0 || rect(4) <= 0
            set(app.resultBox, 'String', 'ROI selection cancelled.');
            return;
        end

        [x1, y1, x2, y2] = clampRect(rect, size(app.rgbImage, 2), size(app.rgbImage, 1));
        rectangle(app.ax, 'Position', [x1 y1 x2 - x1 + 1 y2 - y1 + 1], ...
            'EdgeColor', 'g', 'LineWidth', 2);

        roiRgb = app.rgbDouble(y1:y2, x1:x2, :);
        roiLab = app.labImage(y1:y2, x1:x2, :);
        roiHsv = app.hsvImage(y1:y2, x1:x2, :);
        roiXyz = app.xyzImage(y1:y2, x1:x2, :);

        sample.x = round((x1 + x2) / 2);
        sample.y = round((y1 + y2) / 2);
        sample.rgb = squeeze(mean(reshape(roiRgb, [], 3), 1));
        sample.hsv = squeeze(mean(reshape(roiHsv, [], 3), 1));
        sample.xyz = squeeze(mean(reshape(roiXyz, [], 3), 1));
        sample.lab = squeeze(mean(reshape(roiLab, [], 3), 1));
        sample.labStd = squeeze(std(reshape(roiLab, [], 3), 0, 1));
        sample.roi = [x1 y1 x2 y2];

        resultText = sprintf([ ...
            'ROI Mean Color\n' ...
            'ROI: x=%d to %d, y=%d to %d\n\n' ...
            '%s\n\n' ...
            'LAB std: L*=%.2f, a*=%.2f, b*=%.2f'], ...
            x1, x2, y1, y2, ...
            formatSampleText("", sample), ...
            sample.labStd(1), sample.labStd(2), sample.labStd(3));

        set(app.resultBox, 'String', resultText);

        app.results(end + 1, :) = makeResultRow("ROI Mean", sample.x, sample.y, sample.rgb, sample.lab, NaN);
        set(app.table, 'Data', app.results);
        guidata(app.fig, app);
    end

    function exportCsv(~, ~)
        app = guidata(gcbf);

        if isempty(app.results)
            warndlg('No results to export.', 'Export CSV');
            return;
        end

        [fileName, folderName] = uiputfile('cielab_results.csv', 'Export CSV');
        if isequal(fileName, 0)
            return;
        end

        tableData = cell2table(app.results, ...
            'VariableNames', {'Type', 'X', 'Y', 'R', 'G', 'B', 'Lstar', 'astar', 'bstar', 'DeltaE'});
        writetable(tableData, fullfile(folderName, fileName));
        msgbox('CSV exported successfully.', 'Export CSV');
    end

    function clearMarks(~, ~)
        app = guidata(gcbf);

        if isempty(app.rgbImage)
            return;
        end

        imshow(app.rgbImage, 'Parent', app.ax);
        title(app.ax, sprintf('Image: %s', getFileName(app.imagePath)), 'Interpreter', 'none');
        set(app.resultBox, 'String', 'Marks cleared.');
        guidata(app.fig, app);
    end
end

function ok = hasImage(app)
    ok = ~isempty(app.rgbImage);
    if ~ok
        warndlg('Please load an image first.', 'No Image');
    end
end

function [x, y] = pickPoint(app)
    [x, y] = pickPoints(app, 1);
end

function [x, y] = pickPoints(app, n)
    [x, y] = ginput(n);
    x = round(x);
    y = round(y);

    imageHeight = size(app.rgbImage, 1);
    imageWidth = size(app.rgbImage, 2);

    x = min(max(x, 1), imageWidth);
    y = min(max(y, 1), imageHeight);
end

function sample = samplePoint(app, x, y)
    sample.x = x;
    sample.y = y;
    sample.rgb = squeeze(app.rgbDouble(y, x, :))';
    sample.hsv = squeeze(app.hsvImage(y, x, :))';
    sample.xyz = squeeze(app.xyzImage(y, x, :))';
    sample.lab = squeeze(app.labImage(y, x, :))';
end

function addPointMark(app, x, y, color, labelText)
    hold(app.ax, 'on');
    plot(app.ax, x, y, 'o', ...
        'MarkerSize', 10, ...
        'LineWidth', 2, ...
        'MarkerEdgeColor', color);
    text(app.ax, x + 8, y - 8, labelText, ...
        'Color', color, ...
        'FontSize', 12, ...
        'FontWeight', 'bold');
    hold(app.ax, 'off');
end

function textOut = formatSampleText(titleText, sample)
    if strlength(string(titleText)) > 0
        prefix = sprintf('%s\n', titleText);
    else
        prefix = '';
    end

    textOut = sprintf([ ...
        '%s' ...
        'Position: x=%d, y=%d\n' ...
        'RGB: R=%.4f, G=%.4f, B=%.4f\n' ...
        'HSV: H=%.4f, S=%.4f, V=%.4f\n' ...
        'XYZ: X=%.4f, Y=%.4f, Z=%.4f\n' ...
        'LAB: L*=%.4f, a*=%.4f, b*=%.4f'], ...
        prefix, sample.x, sample.y, ...
        sample.rgb(1), sample.rgb(2), sample.rgb(3), ...
        sample.hsv(1), sample.hsv(2), sample.hsv(3), ...
        sample.xyz(1), sample.xyz(2), sample.xyz(3), ...
        sample.lab(1), sample.lab(2), sample.lab(3));
end

function row = makeResultRow(typeName, x, y, rgb, lab, deltaValue)
    row = {char(typeName), x, y, ...
        rgb(1), rgb(2), rgb(3), ...
        lab(1), lab(2), lab(3), deltaValue};
end

function formulaName = selectedDeltaFormula(app)
    formulaList = get(app.deltaPopup, 'String');
    formulaName = formulaList{get(app.deltaPopup, 'Value')};
end

function deltaValue = calculateDeltaE(labOne, labTwo, formulaName)
    switch upper(formulaName)
        case 'CIE76'
            deltaValue = deltaE76(labOne, labTwo);
        case 'CIE94'
            deltaValue = deltaE94(labOne, labTwo);
        case 'CIEDE2000'
            deltaValue = deltaE2000(labOne, labTwo);
        otherwise
            error('Unknown Delta E formula: %s', formulaName);
    end
end

function deltaValue = deltaE76(labOne, labTwo)
    deltaValue = sqrt(sum((labOne - labTwo) .^ 2));
end

function deltaValue = deltaE94(labOne, labTwo)
    l1 = labOne(1);
    a1 = labOne(2);
    b1 = labOne(3);
    l2 = labTwo(1);
    a2 = labTwo(2);
    b2 = labTwo(3);

    deltaL = l1 - l2;
    c1 = sqrt(a1 ^ 2 + b1 ^ 2);
    c2 = sqrt(a2 ^ 2 + b2 ^ 2);
    deltaC = c1 - c2;
    deltaA = a1 - a2;
    deltaB = b1 - b2;
    deltaH2 = max(0, deltaA ^ 2 + deltaB ^ 2 - deltaC ^ 2);

    kL = 1;
    kC = 1;
    kH = 1;
    k1 = 0.045;
    k2 = 0.015;

    sL = 1;
    sC = 1 + k1 * c1;
    sH = 1 + k2 * c1;

    deltaValue = sqrt( ...
        (deltaL / (kL * sL)) ^ 2 + ...
        (deltaC / (kC * sC)) ^ 2 + ...
        deltaH2 / ((kH * sH) ^ 2));
end

function deltaValue = deltaE2000(labOne, labTwo)
    l1 = labOne(1);
    a1 = labOne(2);
    b1 = labOne(3);
    l2 = labTwo(1);
    a2 = labTwo(2);
    b2 = labTwo(3);

    kL = 1;
    kC = 1;
    kH = 1;

    c1 = sqrt(a1 ^ 2 + b1 ^ 2);
    c2 = sqrt(a2 ^ 2 + b2 ^ 2);
    cMean = (c1 + c2) / 2;

    g = 0.5 * (1 - sqrt((cMean ^ 7) / (cMean ^ 7 + 25 ^ 7)));
    a1Prime = (1 + g) * a1;
    a2Prime = (1 + g) * a2;

    c1Prime = sqrt(a1Prime ^ 2 + b1 ^ 2);
    c2Prime = sqrt(a2Prime ^ 2 + b2 ^ 2);

    h1Prime = hueAngle(a1Prime, b1);
    h2Prime = hueAngle(a2Prime, b2);

    deltaLPrime = l2 - l1;
    deltaCPrime = c2Prime - c1Prime;

    if c1Prime * c2Prime == 0
        deltaHPrimeAngle = 0;
    elseif abs(h2Prime - h1Prime) <= 180
        deltaHPrimeAngle = h2Prime - h1Prime;
    elseif h2Prime - h1Prime > 180
        deltaHPrimeAngle = h2Prime - h1Prime - 360;
    else
        deltaHPrimeAngle = h2Prime - h1Prime + 360;
    end

    deltaHPrime = 2 * sqrt(c1Prime * c2Prime) * sind(deltaHPrimeAngle / 2);

    lMeanPrime = (l1 + l2) / 2;
    cMeanPrime = (c1Prime + c2Prime) / 2;

    if c1Prime * c2Prime == 0
        hMeanPrime = h1Prime + h2Prime;
    elseif abs(h1Prime - h2Prime) <= 180
        hMeanPrime = (h1Prime + h2Prime) / 2;
    elseif h1Prime + h2Prime < 360
        hMeanPrime = (h1Prime + h2Prime + 360) / 2;
    else
        hMeanPrime = (h1Prime + h2Prime - 360) / 2;
    end

    t = 1 ...
        - 0.17 * cosd(hMeanPrime - 30) ...
        + 0.24 * cosd(2 * hMeanPrime) ...
        + 0.32 * cosd(3 * hMeanPrime + 6) ...
        - 0.20 * cosd(4 * hMeanPrime - 63);

    deltaTheta = 30 * exp(-((hMeanPrime - 275) / 25) ^ 2);
    rC = 2 * sqrt((cMeanPrime ^ 7) / (cMeanPrime ^ 7 + 25 ^ 7));
    sL = 1 + (0.015 * (lMeanPrime - 50) ^ 2) / sqrt(20 + (lMeanPrime - 50) ^ 2);
    sC = 1 + 0.045 * cMeanPrime;
    sH = 1 + 0.015 * cMeanPrime * t;
    rT = -sind(2 * deltaTheta) * rC;

    deltaValue = sqrt( ...
        (deltaLPrime / (kL * sL)) ^ 2 + ...
        (deltaCPrime / (kC * sC)) ^ 2 + ...
        (deltaHPrime / (kH * sH)) ^ 2 + ...
        rT * (deltaCPrime / (kC * sC)) * (deltaHPrime / (kH * sH)));
end

function h = hueAngle(aValue, bValue)
    if aValue == 0 && bValue == 0
        h = 0;
        return;
    end

    h = atan2d(bValue, aValue);
    if h < 0
        h = h + 360;
    end
end

function [x1, y1, x2, y2] = clampRect(rect, imageWidth, imageHeight)
    x1 = max(1, min(imageWidth, rect(1)));
    y1 = max(1, min(imageHeight, rect(2)));
    x2 = max(1, min(imageWidth, rect(1) + rect(3)));
    y2 = max(1, min(imageHeight, rect(2) + rect(4)));

    if x2 < x1
        temp = x1;
        x1 = x2;
        x2 = temp;
    end

    if y2 < y1
        temp = y1;
        y1 = y2;
        y2 = temp;
    end
end

function name = getFileName(pathText)
    [~, baseName, extension] = fileparts(char(pathText));
    name = [baseName extension];
end
