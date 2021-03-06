public with sharing class GW_CTRL_EngagementRollup {
	
/*******************************************************************************************************
* @author Matthew Scholtz
* @date 7/1/2012
* @description Controller for "Engagement Rollup" tab that manually launches Engage rollup batch processes
*
* Written by Matthew Scholtz and Evan Callahan, copyright (c) 2012 Groundwire
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
*/

    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public GW_CTRL_EngagementRollup() {
        batchRunning = false;

        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {     
        }  
        
        if (oid != null) {
            batching = false;           
        } else {
            batching = true;
        }
    }

/*    
    public PageReference startAction() {
        PageReference ref;
        if (oid != null) {
            
            // run the rollup for the specified object
            GW_OppRollups rg = new GW_OppRollups();
            if (objectId.startsWith('001'))
                rg.RollupAccount(oid);
            else if (objectId.startsWith('003'))
                rg.RollupContact(oid);
            else 
                rg.RollupHousehold(oid);
                 
            ref = new PageReference('/' + oid);
            ref.setRedirect(true);
        }
        return ref;
    }
*/

    public PageReference rollup() {
    	
    	GW_BATCH_EngagementRollup er = new GW_BATCH_EngagementRollup(false);
    	er.execute(null);
        batchRunning = true;
        return null;                
    }

	
	public PageReference campaignRollup() {
    	GW_BATCH_CampaignEngagementRollup campRollup = new GW_BATCH_CampaignEngagementRollup();
    	campRollup.execute(null);
        batchRunning = true;
        return null;                
		
	}

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

    // TEST METHOD
    public static testMethod void testRollup() {
        GW_CTRL_EngagementRollup controller = new GW_CTRL_EngagementRollup();
        system.assertEquals(true, controller.batching);
        system.assertEquals(false, controller.batchRunning);
        system.assertNotEquals(null, controller.cancel());
        // specifically not calling rollup, since we'll test the batch class seperately,
        // and we don't need to see its potential errors here!
   }
}