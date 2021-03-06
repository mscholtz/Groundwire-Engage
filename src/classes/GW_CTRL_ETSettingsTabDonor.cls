public with sharing class GW_CTRL_ETSettingsTabDonor {

/*******************************************************************************************************
* @author David Habib
* @date 7/1/2012
* @description Controller for settings wizard, donations tab
*
* Written by David Habib, copyright (c) 2012 Groundwire
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
*/


	// constructor
	public GW_CTRL_ETSettingsTabDonor(GW_CTRL_ETSettingsWizard cWiz) {
		ctrlWizard = cWiz;
		isEditingTab = false;
	}
	
	private GW_CTRL_ETSettingsWizard ctrlWizard { get; set; }
	
    public List<Engagement_Donor_Level_Settings__c> listDonorLevelSettings {
    	get {
    		if (listDonorLevelSettings == null) {
    			listDonorLevelSettings = Engagement_Donor_Level_Settings__c.getall().values();    			
    			// sort list by increasing dollar amounts
    			listDonorLevelSettings = sortDonorLevelSettings(listDonorLevelSettings);    			    			
    			AddEmptyRows();
    		}
    		return listDonorLevelSettings;
    	}
    	set;
    }


    private list<Engagement_Donor_Level_Settings__c> sortDonorLevelSettings (list<Engagement_Donor_Level_Settings__c> listDLS) {
    	list<Engagement_Donor_Level_Settings__c> listResult = new list<Engagement_Donor_Level_Settings__c>();
    	
    	//create a map of donation amount to donor level setting
    	map<Double, list<Engagement_Donor_Level_Settings__c>> mapAmountToDLS = new map<Double, list<Engagement_Donor_Level_Settings__c>>();
    	
    	for (Engagement_Donor_Level_Settings__c dls : listDLS) {
    		//if our map doesn't contain this dls, create a new list, otherwise add to the list
    		if (mapAmountToDLS.get(dls.Lower_Limit__c) == null) {
    			mapAmountToDLS.put(dls.Lower_Limit__c, new List<Engagement_Donor_Level_Settings__c>());
    		}
    		mapAmountToDLS.get(dls.Lower_Limit__c).add(dls);
    	}
    	
    	//use SF's standard sort method on the datetimes
    	list<Double> keys = new list<Double>(mapAmountToDLS.keySet());
    	keys.sort();
    	
    	//rebuild list in order
    	for (Double key : keys) {
    		listResult.addAll(mapAmountToDLS.get(key));
    	}
    	return listResult;
    }
		
	public PageReference AddEmptyRows() {
		for (integer i = listDonorLevelSettings.size(); i < 8; i++) {
			listDonorLevelSettings.add(new Engagement_Donor_Level_Settings__c());
		}
		return null;
	}	

	public boolean isEditingTab { get; set; }
	
	public PageReference editTab() {
		isEditingTab = true;
		ctrlWizard.strCurrentTab = 'tabDonor';
		return null;
	}
	
	public PageReference saveTab() {
		list<Engagement_Donor_Level_Settings__c> listDLStoDel = new list<Engagement_Donor_Level_Settings__c>();
		  
		// go thru the field settings, give any new ones names, and delete empty ones
		for (integer i = listDonorLevelSettings.size()-1; i >= 0; i--) {
			Engagement_Donor_Level_Settings__c dls = listDonorLevelSettings[i];
			if (ctrlWizard.isnullNum(dls.Level__c) &&
				ctrlWizard.isnullNum(dls.Lower_Limit__c)) {
					if (dls.Id == null) {
						// it's a new empty dls; just remove it
						listDonorLevelSettings.remove(i);
					} else {
						// it's an existing, but cleared entry; delete it.
						listDonorLevelSettings.remove(i);
						listDLStoDel.add(dls);
					}
			}
		}

		// name new settings
		ctrlWizard.nameNewSettings(listDonorLevelSettings, 'DonorLevel');
				
		if (listDLStoDel.size() > 0) delete listDLStoDel;
        try {
			upsert listDonorLevelSettings;
        } catch (exception ex) {
        	ApexPages.addMessages(ex);
        	return null;
        }		
		// force list to get reloaded and sorted
		listDonorLevelSettings = null;
		
        try {
			upsert ctrlWizard.etSettings;
        } catch (exception ex) {
        	ApexPages.addMessages(ex);
        	return null;
        }		
		isEditingTab = false;
		ctrlWizard.strCurrentTab = 'tabDonor';
		return null;
	}
	
	public PageReference cancelTab() {
		isEditingTab = false;
		ctrlWizard.etSettings = null;
		PageReference p = new PageReference('/apex/ETSettingsWizard?currentTab=tabDonor' + ctrlWizard.strSalesforceTabNameParam);
		p.setRedirect(true);
		return p;
	}

	//---------------------------------------- TEST CODE -------------------------------------------------
	static testmethod void TestTabDonor() {
		GW_CTRL_ETSettingsWizard ctrl = new GW_CTRL_ETSettingsWizard();
		system.assert(ctrl.ctabDonor != null);
		system.assertEquals(ctrl.ctabDonor.ctrlWizard, ctrl);
		system.assertEquals(ctrl.ctabDonor.isEditingTab, false);
		system.assert(ctrl.ctabDonor.listDonorLevelSettings != null);
		ctrl.ctabDonor.editTab();
		system.assertEquals(ctrl.strCurrentEditTab, 'tabDonor');
		ctrl.ctabDonor.saveTab();
		system.assertEquals(ctrl.strCurrentEditTab, null);
		system.assert(ctrl.ctabDonor.cancelTab() != null);		
	}

}