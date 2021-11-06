
%% generate a fake 10s of acquisition with some more activity around some triggers

% background activity
spikes = rand(100,1)*10;

% triggered activity
triggers = cumsum(rand(10, 1));
triggers = triggers * 9/triggers(end);
ntrig = length(triggers);
for t = brick.row(triggers)
    spikes = [spikes; t+rand(5,1)*.1];
end

% sort spike times
spikes = sort(spikes);

% display all the spikes
brick.figure('spikes', [800, 150])
brick.rasterplot(spikes)
set(gca,'ylim',[.5 1.5])
tps_displaystim(brick.row(triggers))

%% display as a raster

% display 200ms before and 500ms after each trigger
window = [-.2 .5];

% keep only spikes inside the window for each trigger
raster = cell(1, ntrig);
for i = 1:ntrig
    x = spikes - triggers(i);
    raster{i} = x(x>window(1) & x<window(2));
end

% display
brick.figure('raster')
subplot(311)
brick.rasterplot(raster)
set(gca,'ydir','reverse')
tps_displaystim(0)
xlabel 'time (s)', ylabel 'trigger'

%% STA

% convert the spikes inside 'raster' in instantaneous rates
dt = .01; % time bin: 10ms
times = window(1)-dt/2:dt:window(2)+dt/2;  % the +-dt/2 is there so that 0 is at the border between two bins
rasterrate = brick.timevector(raster, times, 'rate');
subplot(312)
imagesc(times, 1:ntrig, rasterrate')
h = tps_displaystim(0, 'color', 'w');
uistack(h, 'top')  % stim bar was automatically place under the image..., bring it forward
xlabel 'time (s)', ylabel 'trigger'

% average
y = mean(rasterrate, 2);

% display
subplot(313)
bar(times, y, 1)
tps_displaystim(0)
xlabel 'time (s)'
ylabel 'spiking rate'