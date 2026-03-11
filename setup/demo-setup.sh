#!/bin/bash

# Check if stepNumber is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 stepNumber"
  exit 1
fi

stepNumber=$1

case $stepNumber in
  6)
	source ./load-config.sh print
    ;;
  *)
	source ./load-config.sh
    ;;
esac

baseURL="$scheme://$hostname:$port"

push_deploy_restart_wait() {
    local step=$1
	echo "Step $step: PUSH (yes, PUSH!) the clone to origin"
	echo "        e.g."
	echo "        git push origin master"
    echo "        WAIT for Jenkins to do a build"
	echo "        DEPLOY the build to PRD"
	echo "        RESTART the Liferay Service after it warms up (might be necessary for site initializers to work)"
	echo "        WAIT for the restart to finish"
}

add_view_download_permissions() {
    local cMSBasicDocumentId="$1"

    permissionsPayload='[
      {
        "roleName": "Guest",
        "actionIds": ["VIEW", "DOWNLOAD_FILE"]
      }
    ]'

    permissionsUrl="$baseURL/o/cms/basic-documents/$cMSBasicDocumentId/permissions"

    response=$(
      curl -sS -X PUT \
        -u "$adminEmail:$adminPassword" \
        -H "Content-Type: application/json" \
        "$permissionsUrl" \
        -d "$permissionsPayload"
    )

    echo "Updated permissions for CMSBasicDocumentId: $cMSBasicDocumentId"
    echo "$response"
}

case $stepNumber in
  1)
	echo "Step $stepNumber: Sign-in to the PRD site provisioned by SSA as ${ColorOn}test@liferay.com${ColorOff} and change the password to ${ColorOn}test1${ColorOff}"
    ;;

  2)
    echo "Step $stepNumber: Under Instance Settings > User Authentication:"
    echo "        UNCHECK \"Require strangers to verify their email address?\""
    echo "        UNCHECK \"Require password for email or screen name updates?\""
    echo "        CLICK \"Save\""
	echo " "
    echo "        Under Instance Settings > Infrastructure > Site Scope > Session Timeout:"
    echo "        CHECK \"Auto Extend\""
    echo "        CLICK \"Update\""
	echo " "
    echo "        Under Instance Settings > Page Fragments > Virtual Instance Scope > Page Fragments:"
    echo "        CHECK \"Propagate Fragment Changes Automatically\""
    echo "        CLICK \"Save\""
	echo " "
    echo "        Under Instance Settings > AI Creator > OpenAI:"
    echo "        PASTE \"API Key\""
    echo "        CLICK \"Save\""
	echo " "
    echo "        NAVIGATE TO App Menu > Control Panel > Security > Password Policies > Default Password Policy"
	echo "        DISABLE \"PASSWORD CHANGES > Change Required\""
	echo "        SAVE the password policy"
    ;;

  3)
    echo "Step $stepNumber: Under Instance Settings  > Feature Flags > Release"
	echo "        ENABLE \"LPD-32050\" (Enhancements to Object Entry Localization)"
	echo "        ENABLE \"LPD-34594\" (Root Object Definitions)"
	echo " "
    echo "        Under Instance Settings  > Feature Flags > Beta"
	echo "        ENABLE \"LPD-17564\" (CMS 2.0)"
    ;;

  4)
	echo "Step $stepNumber: CREATE an Asset Library named ${ColorOn}Images Asset Library${ColorOff}"
	echo "        SHARE the Asset Library with the ${ColorOn}Liferay DXP${ColorOff} site and MAKE-UNSEARCHABLE"
    ;;

  5)
	echo "Step $stepNumber: Under the Asset Library Documents and Media, create a folder named ${ColorOn}Personas${ColorOff} and determine the ${ColorOn}assetLibraryPersonasFolderId${ColorOff}\n"
	# As of release 2024.q3.3 the headless REST API does not have an endpoint that supports creation of an asset library
	#curl -X POST -u $adminEmail:$adminPassword -H "Content-Type: application/json" "$baseURL/o/headless-asset-library/v1.0/asset-libraries" -d '{"name": "Images"}'
	#curl -X POST -u $adminEmail:$adminPassword -H "Content-Type: application/json" "$baseURL/o/headless-asset-library/v1.0/asset-libraries" -d '{"name": "Shared"}'
    ;;

  6)
    echo "Step $stepNumber: Edit config.json and FIX the ${ColorOn}values${ColorOff} ^^^ above ^^^ (including the ${ColorOn}assetLibraryPersonasFolderId${ColorOff} from the previous step"
    ;;

  7)
    echo "Step $stepNumber: Fixing administrator screenName=[$adminAlternateName] firstName=[$adminGivenName], lastName=[$adminFamilyName], and emailAddress=[$adminEmail]"
	json='{"alternateName": "'$adminAlternateName'", "emailAddress": "'$adminEmail'", "currentPassword": "'$adminPasswordDefault'", "password": "'$adminPassword'", "givenName": "'$adminGivenName'", "familyName": "'$adminFamilyName'", "jobTitle": "Liferay DXP Admin", "status": "Active"}'
	curl -X PUT -u $adminEmailDefault:$adminPasswordDefault -H "Content-Type: application/json" "$baseURL/o/headless-admin-user/v1.0/user-accounts/$adminUserId" -d "${json}"
    ;;

  8)
    echo "Step $stepNumber: Uploading administrator PROFILE image"
	curl -X POST -u $adminEmail:$adminPassword -H "Content-Type: multipart/form-data" -F "image=@$adminProfileImagePath" "$baseURL/o/headless-admin-user/v1.0/user-accounts/$adminUserId/image"
	echo " "
    echo "Step $stepNumber: Uploading administrator PERSONA image to the Personas folder"
	response=$(curl -S -X POST -u "$adminEmail:$adminPassword" -H "Content-Type: multipart/form-data" -F "file=@$adminProfileImagePath" "$baseURL/o/headless-delivery/v1.0/document-folders/$assetLibraryPersonasFolderId/documents")
	documentId=$(echo "$response" | jq -r '.id')
	curl -X PUT -u $adminEmail:$adminPassword -H "Content-Type: application/json" "$baseURL/o/headless-delivery/v1.0/documents/$documentId/permissions" -d '[{"actionIds":["VIEW","DOWNLOAD"],"roleName":"Guest"}]'
    ;;

  9)
	echo "Step $stepNumber: Clone the GitHub repo locally, and determine the clone's name (e.g. ${ColorOn}$project${ColorOff})"
    ;;

  10)
    echo "Step $stepNumber: EDIT liferay/LCP.json in the clone (the ${ColorOn}memory${ColorOff} one is close to the top, ${ColorOn}LIFERAY_JVM_OPTS${ColorOff} close to the bottom)"
    echo "         \"${ColorOn}memory${ColorOff}\": ${ColorOn}16384${ColorOff},"
	echo "         \"${ColorOn}LIFERAY_JVM_OPTS${ColorOff}\": \"${ColorOn}-Xms8192m -Xmx12288m -XX:MaxMetaspaceSize=3072m${ColorOff}\""
	echo " "
	echo "        NOTE: The following is a workaround for LPD-73649, until it is fixed in Liferay PaaS:"
	echo " "
	echo "        Add the following immediately before (or after) the LIFERAY_JVM_OPTS environment variable:"
	echo " "
	echo "        \"${ColorOn}LCP_DXP_AGENT_DOWNLOAD_URL${ColorOff}\": \"${ColorOn}https://cdn.liferay.cloud/liferay-dxp/liferay-dxp-agent-jakarta-LPD-73649.jar${ColorOff}\","
	echo "         STAGE and COMMIT"
    ;;

  11)
	echo "Step $stepNumber: COPY ../liferay/configs/${ColorOn}common${ColorOff}/portal-common.properties to $project/liferay/configs/${ColorOn}common${ColorOff}"
    echo "         COPY ../liferay/configs/${ColorOn}prd${ColorOff}/portal-ext.properties to $project/liferay/configs/${ColorOn}prd${ColorOff}"
	echo "         STAGE and COMMIT"
    ;;

  12)
	push_deploy_restart_wait 12;
    ;;

  13)
    echo "Step $stepNumber: This step is a placholder for the future. Skip for now"
	#echo "Step $stepNumber: Deploy the ${ColorOn}global${ColorOff}-site-initializer by doing the following:"
	#echo "         pushd ../liferay/client-extensions/global-site-initializer"
	#echo "         blade gw clean build"
	#echo "         lcp deploy --extension dist/global-site-initializer.zip -p $project-$projectEnv"
	#echo "         popd"
    ;;

  14)
    echo "Step $stepNumber: Create a CMS 2.0 Space named \"Images\""
	echo " "
	echo "           CLICK \"View all Files\" in the space"
	echo "           CREATE a folder named \"${ColorOn}Personas${ColorOff}\" in the space"
	echo "           CLICK on the Personas folder and observe the folder ID as the last integer in the URL, e.g. /web/cms/e/view-folder/29649/${ColorOn}37766${ColorOff}"
	echo "           EDIT config.json and set the value of ${ColorOn}spacePersonasFolderId${ColorOff} accordingly"
    ;;

  15)
	echo "Step $stepNumber: Uploading administrator PERSONA image to the Personas folder"

	#cmsBaseRoot="$baseURL/o/c/images"
	cmsBaseRoot="$baseURL/o/cms/basic-documents"
	createUrl="$cmsBaseRoot/scopes/$imagesScopeKey"

	title="$adminGivenName $adminFamilyName"
	fileName="$(basename "$adminProfileImagePath")"

	# Single-line base64 (BSD/macOS base64 wraps by default)
	fileBase64="$(base64 < "$adminProfileImagePath" | tr -d '\n\r')"

	createPayload='{
  	"title": "'"$title"'",
  	"title_i18n": { "en_US": "'"$title"'" },
  	"objectEntryFolderId": '"$spacePersonasFolderId"',
  	"file": {
    	"name": "'"$fileName"'",
    	"fileBase64": "'"$fileBase64"'"
  	},
  	"file_i18n": {
    	"en_US": {
      	"name": "'"$fileName"'",
      	"fileBase64": "'"$fileBase64"'"
    	}
  	}
	}'

	echo "URL: $createUrl"

	response=$(
  	curl -sS -X POST \
    	-u "$adminEmail:$adminPassword" \
    	-H "Content-Type: application/json" \
    	"$createUrl" \
    	-d "$createPayload"
	)

	imageId=$(echo "$response" | jq -r '.id')
	echo "Created CMS imageId: $imageId"

	echo $response

	add_view_download_permissions "$imageId"

	;;

  16)
    echo "Step $stepNumber: This step is a placholder for the future. Skip for now"
    #echo "Step $stepNumber: OBSERVE: The value of the ${ColorOn}ID${ColorOff} of the Press Release structure (needed for the ${ColorOn}subTypeId${ColorOff} in the next step)"
    ;;

  17)
	echo "Step $stepNumber: Deploy the ${ColorOn}guest${ColorOff}-site-initializer by doing the following:"
	echo "         pushd ../liferay/client-extensions/guest-site-initializer"
    echo "         EDIT the value of ${ColorOn}subtypeId${ColorOff} in site-initializer/layout-page-templates/display-page-templates/press-release-dpt/display-page-template.json"
	echo "         blade gw clean build"
	echo "         lcp deploy --extension dist/guest-site-initializer.zip -p $project-$projectEnv"
	echo "         popd"
    ;;

  18)
	echo "Step $stepNumber: Make sure that the Guest site initializer worked by verifying that it has, for example, the External Video Shortcut DPT"
    ;;

  19)
    echo "Step $stepNumber: SET the \"Press Release\" DPT as the default" in the Liferay DXP site
	echo "         NOTE: It will get overwritten on subsequent restarts, so might want to make a copy of it if it has to change"
    ;;

  20)
    echo "Step $stepNumber: Make a copy the widget templates, since they will get overwritten on restarts"
	echo "         COPY \"Article Type\" to a new name"
	echo "         COPY \"File Type\" to a new name"
	echo "         COPY \"Media Type\" to a new name"
	echo "         COPY \"Search Results Preview\" to a new name"
    ;;

  21)
    echo "Step $stepNumber: CREATE a style book using https://dialect-style-book-generator.web.app"
	echo "         IMPORT the style book into the site"
	echo "         SET the imported style book as the default"
    ;;

  22)
    echo "Step $stepNumber: COPY the \"Demo Master\" page to a new project-specific master page, since it gets overwritten on restarts"
	echo "         SET the new project-specific master page as the default"
    ;;

  23)
	echo "Step $stepNumber: DELETE the OOTB Search Widget Page"
    echo "         CREATE a content page named ${ColorOn}Search${ColorOff} off the Demo Template for Search"
	echo "         SET the Display Template of the \"Article Type\" custom facet to the copied one"
	echo "         SET the Display Template of the \"File Type\" custom facet to the copied one"
	echo "         SET the Display Template of the \"Media Type\" custom facet to the copied one"
	echo "         SET the Display Template of the \"Search Results\" widget to the copied one"
	echo "         PUBLISH the Search content page"
	echo "         EDIT the new project-specific master page and configure the search box so that the Destination Page field is ${ColorOn}/search${ColorOff}"
	echo "         PUBLISH the project-specific master page"
    ;;

  24)
    echo "Step $stepNumber: Make a copy the Sign-In Utility Page template, since it will get overwritten on restarts"
	echo "         COPY \"Sign-In\" to a new name"
	echo "         EDIT the ${ColorOn}new Sign-In${ColorOff} page"
    echo "         SET the Master Page Template for the ${ColorOn}new Sign-In${ColorOff} page to the copied Master Page Template and Publish the changes"
	echo "         EDIT+PUBLISH the \"Sign-In\" page"
	echo "         SET the \"Sign-In\" as default"
    ;;

  25)
    echo "Step $stepNumber: SET the Master Page Template for the ${ColorOn}Search${ColorOff} page to the copied Master Page Template and Publish the changes"
    echo "         SET the Master Page Template for the ${ColorOn}Home${ColorOff} page to the copied Master Page Template and Publish the changes"
    ;;

  *)
    echo "Invalid step number. Please provide a value between 1 and 25."
    exit 1
    ;;

esac
