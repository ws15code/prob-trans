% toPlotPh    

Y = pdist(toPlotPh, 'seuclidean'); %Y = pdist(wFeaAvgMul(:,interval), 'euclidean');
[x,~] = mdscale(Y,size(toPlotPh,1)); % multidimensional scaling ph

stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};

% 2D
figure;
scatter(x(:,1),x(:,2),'w','filled');
text(x(:,1),x(:,2),stimulusName(:), 'horizontal','left', 'vertical','bottom','FontSize',22,'fontname','Times','Color','r')
% 
% title('MDS phonemes','fontsize',14)
% set(gcf,'color','w');
% %     legend(legendNames,'Location','Best')
% xlabel('First eigenvariate','fontsize',14);
% ylabel('Second eigenvariate','fontsize',14)
% % xlim([-0.2, 0.2])
% % ylim([-0.2, 0.2])
% 
% text(x(consonantsIdx,1),x(consonantsIdx,2),stimulusName(consonantsIdx), 'horizontal','left', 'vertical','bottom','FontSize',22,'fontname','Times','Color','b')
% 
% % set(gcf,'OuterPosition',figPosition);export_fig('-tif','-r300', 'mdsVowelsConsonants2D.tiff')
% savefig('mdsVowelsConsonants2D.fig')
