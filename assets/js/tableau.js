//Global Variables
var viz, workbook, activeSheet;

////////////////////////////////////////////////////////////////////////////////
// Create a View

//initialize Eric's main viz
initializeViz("tableauViz-2", "https://public.tableau.com/shared/5SHKZF3NP?:embed=y&:showTabs=y&:display_count=yes");

//initialize Evan's viz
initializeViz("tableauViz-mgd1", "https://public.tableau.com/views/Evan_Viz_Drafts_01/Draft-Storyboard?:embed=y&:display_count=yes&:showTabs=n");

function initializeViz(phdiv, phUrl) {

		var placeholderDiv = document.getElementById(phdiv)
		var url = phUrl

	  //var placeholderDiv = document.getElementById("tableauViz-2");
		//var url = "https://public.tableau.com/shared/5SHKZF3NP?:embed=y&:showTabs=y&:display_count=yes"

	  var options = {
		width: placeholderDiv.offsetWidth,
		height: placeholderDiv.offsetHeight,
		hideTabs: true,
		hideToolbar: true,
		onFirstInteractive: function () {
		  workbook = viz.getWorkbook();
		  activeSheet = workbook.getActiveSheet();
		}
	  };
	  try{
			viz = new tableauSoftware.Viz(placeholderDiv, url, options);
		}

		catch (err){
			alert(err.message);
		}
}

////////////////////////////////////////////////////////////////////////////////
// Export

function exportImage() {
  viz.showExportImageDialog();
}
