package Google::API::Client;

use strict;
use 5.008_001;
our $VERSION = '0.09';

use Google::API::Method;
use Google::API::Resource;


use constant AUTH_URI => 'https://accounts.google.com/o/oauth2/auth';
use constant TOKEN_URI => 'https://accounts.google.com/o/oauth2/token';

# apis, assign value at the last part
my %apis;

sub new {
    my $class = shift;
    my ($param) = @_;
    unless (defined $param->{ua}) {
        $param->{ua} = $class->_new_ua;
    }
    unless (defined $param->{json_parser}) {
        $param->{json_parser} = $class->_new_json_parser;
    }
    bless { %$param }, $class;
}

sub build {
    my $self = shift;
    my ($service, $version, $args, $from_cache) = @_;

    my $discovery_service_url = 'https://www.googleapis.com/discovery/v1/apis/{api}/{apiVersion}/rest';
    $discovery_service_url =~ s/{api}/$service/;
    $discovery_service_url =~ s/{apiVersion}/$version/;

    my $document;

    if($from_cache){
        unless(exists($apis{$service}{$version})){
            die "There is no such api $service version $version";
        }
        $document = $apis{$service}{$version};
    }
    else{
        my $req = HTTP::Request->new(GET => $discovery_service_url);
        my $res = $self->{ua}->request($req);
        unless ($res->is_success) {
            # throw an error
            die 'could not get service document.' . $res->status_line;
        }
        $document = $res->content;
    }


    $document = $self->{json_parser}->decode($document);
    $self->build_from_document($document, $discovery_service_url, $args);
}

sub build_from_document {
    my $self = shift;
    my ($document, $url, $args) = @_;
    my $base = $document->{basePath};
    my $base_url = URI->new($url);
    $base_url = URI->new_abs($base, $base_url);
    my $resource = $self->_create_resource($document, $base_url, $args); 
    return $resource;
}

sub _create_resource {
    my $self = shift;
    my ($document, $base_url, $args) = @_;
    my $root_resource_obj = Google::API::Resource->new;
    for my $resource (keys %{$document->{resources}}) {
        my $resource_obj;
        if ($document->{resources}{$resource}{resources}) {
            $resource_obj = $self->_create_resource($document->{resources}{$resource}, $base_url, $args);
        }
        if ($document->{resources}{$resource}{methods}) {
            unless ($resource_obj) {
                $resource_obj = Google::API::Resource->new;
            }
            for my $method (keys %{$document->{resources}{$resource}{methods}}) {
                $resource_obj->set_attr($method, sub {
                    my (%param) = @_;
                    return Google::API::Method->new(
                        ua => $self->{ua},
                        json_parser => $self->{json_parser},
                        base_url => $base_url,
                        doc => $document->{resources}{$resource}{methods}{$method},
                        opt => \%param,
                    );
                });
            }
        }
        $root_resource_obj->set_attr($resource, sub { $resource_obj } );
    }
    if ($document->{auth}) {
        $root_resource_obj->{auth_doc} = $document->{auth};
    }
    return $root_resource_obj;
}

sub _new_ua {
    my $class = shift;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    return $ua;
}

sub _new_json_parser {
    my $class = shift;
    require JSON;
    my $parser = JSON->new;
    return $parser;
}



$apis{mirror}{v1} = <<'EOF';
{
 "kind": "discovery#restDescription",
 "etag": "\"DGgqtFnjgu83tuwvvVNNUhOiHWk/TkhJ1-ITz0PDJP0q_6cuyPtPfFM\"",
 "discoveryVersion": "v1",
 "id": "mirror:v1",
 "name": "mirror",
 "version": "v1",
 "title": "Google Mirror API",
 "description": "API for interacting with Glass users via the timeline.",
 "ownerDomain": "google.com",
 "ownerName": "Google",
 "icons": {
  "x16": "http://www.google.com/images/icons/product/search-16.gif",
  "x32": "http://www.google.com/images/icons/product/search-32.gif"
 },
 "documentationLink": "https://developers.google.com/glass",
 "labels": [
  "limited_availability"
 ],
 "protocol": "rest",
 "baseUrl": "https://www.googleapis.com/mirror/v1/",
 "basePath": "/mirror/v1/",
 "rootUrl": "https://www.googleapis.com/",
 "servicePath": "mirror/v1/",
 "batchPath": "batch",
  "parameters": {
      "alt": {
   "type": "string",
   "description": "Data format for the response.",
   "default": "json",
   "enum": [
    "json"
   ],
   "enumDescriptions": [
    "Responses with Content-Type of application/json"
   ],
   "location": "query"
      },
   "fields": {
   "type": "string",
   "description": "Selector specifying which fields to include in a partial response.",
   "location": "query"
},
       "key": {
   "type": "string",
   "description": "API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.",
   "location": "query"
   },
       "oauth_token": {
   "type": "string",
   "description": "OAuth 2.0 token for the current user.",
   "location": "query"
   },
       "prettyPrint": {
   "type": "boolean",
   "description": "Returns response with indentations and line breaks.",
   "default": "true",
   "location": "query"
   },
       "quotaUser": {
   "type": "string",
   "description": "Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters. Overrides userIp if both are provided.",
   "location": "query"
   },
       "userIp": {
   "type": "string",
   "description": "IP address of the site where the request originates. Use this if you want to enforce per-user limits.",
   "location": "query"
   }
},
 "schemas": {
     "Attachment": {
   "id": "Attachment",
   "type": "object",
   "description": "Represents media content, such as a photo, that can be attached to a timeline item.",
   "properties": {
       "contentType": {
     "type": "string",
     "description": "The MIME type of the attachment."
       },
         "contentUrl": {
     "type": "string",
     "description": "The URL for the content."
     },
         "id": {
     "type": "string",
     "description": "The ID of the attachment."
     },
         "isProcessingContent": {
     "type": "boolean",
     "description": "Indicates that the contentUrl is not available because the attachment content is still being processed. If the caller wishes to retrieve the content, it should try again later."
     }
   }
     },
     "AttachmentsListResponse": {
   "id": "AttachmentsListResponse",
   "type": "object",
   "description": "A list of Attachments. This is the response from the server to GET requests on the attachments collection.",
   "properties": {
       "items": {
     "type": "array",
     "description": "The list of attachments.",
     "items": {
      "$ref": "Attachment"
     }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#attachmentsList.",
     "default": "mirror#attachmentsList"
       }
   }
     },
     "Command": {
   "id": "Command",
   "type": "object",
   "description": "A single menu command that is part of a Contact.",
   "properties": {
       "type": {
     "type": "string",
     "description": "The type of operation this command corresponds to. Allowed values are:  \n- TAKE_A_NOTE - Shares a timeline item with the transcription of user speech from the \"Take a note\" voice menu command.  \n- POST_AN_UPDATE - Shares a timeline item with the transcription of user speech from the \"Post an update\" voice menu command."
       }
   }
     },
     "Contact": {
   "id": "Contact",
   "type": "object",
   "description": "A person or group that can be used as a creator or a contact.",
   "properties": {
       "acceptCommands": {
     "type": "array",
     "description": "A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command.",
     "items": {
      "$ref": "Command"
     }
       },
       "acceptTypes": {
     "type": "array",
     "description": "A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.",
     "items": {
      "type": "string"
     }
       },
       "displayName": {
     "type": "string",
     "description": "The name to display for this contact.",
     "annotations": {
      "required": [
       "mirror.contacts.insert",
       "mirror.contacts.update"
      ]
     }
       },
       "id": {
     "type": "string",
     "description": "An ID for this contact. This is generated by the application and is treated as an opaque token.",
     "annotations": {
      "required": [
       "mirror.contacts.insert",
       "mirror.contacts.update"
      ]
     }
       },
       "imageUrls": {
     "type": "array",
     "description": "Set of image URLs to display for a contact. Most contacts will have a single image, but a \"group\" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.",
     "items": {
      "type": "string"
     },
          "annotations": {
      "required": [
       "mirror.contacts.insert",
       "mirror.contacts.update"
      ]
      }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#contact.",
     "default": "mirror#contact"
       },
         "phoneNumber": {
     "type": "string",
     "description": "Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number."
     },
         "priority": {
     "type": "integer",
     "description": "Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities.",
     "format": "uint32"
     },
         "sharingFeatures": {
     "type": "array",
     "description": "A list of sharing features that a contact can handle. Allowed values are:  \n- ADD_CAPTION",
     "items": {
      "type": "string"
     }
     },
       "source": {
     "type": "string",
     "description": "The ID of the application that created this contact. This is populated by the API"
       },
         "speakableName": {
     "type": "string",
     "description": "Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic."
     },
         "type": {
     "type": "string",
     "description": "The type for this contact. This is used for sorting in UIs. Allowed values are:  \n- INDIVIDUAL - Represents a single person. This is the default. \n- GROUP - Represents more than a single person."
     }
   }
     },
     "ContactsListResponse": {
   "id": "ContactsListResponse",
   "type": "object",
   "description": "A list of Contacts representing contacts. This is the response from the server to GET requests on the contacts collection.",
   "properties": {
       "items": {
     "type": "array",
     "description": "Contact list.",
     "items": {
      "$ref": "Contact"
     }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#contacts.",
     "default": "mirror#contacts"
       }
   }
     },
     "Location": {
   "id": "Location",
   "type": "object",
   "description": "A geographic location that can be associated with a timeline item.",
   "properties": {
       "accuracy": {
     "type": "number",
     "description": "The accuracy of the location fix in meters.",
     "format": "double"
       },
         "address": {
     "type": "string",
     "description": "The full address of the location."
     },
         "displayName": {
     "type": "string",
     "description": "The name to be displayed. This may be a business name or a user-defined place, such as \"Home\"."
     },
         "id": {
     "type": "string",
     "description": "The ID of the location."
     },
         "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#location.",
     "default": "mirror#location"
     },
         "latitude": {
     "type": "number",
     "description": "The latitude, in degrees.",
     "format": "double"
     },
         "longitude": {
     "type": "number",
     "description": "The longitude, in degrees.",
     "format": "double"
     },
         "timestamp": {
     "type": "string",
     "description": "The time at which this location was captured, formatted according to RFC 3339.",
     "format": "date-time"
     }
   }
     },
     "LocationsListResponse": {
   "id": "LocationsListResponse",
   "type": "object",
   "description": "A list of Locations. This is the response from the server to GET requests on the locations collection.",
   "properties": {
       "items": {
     "type": "array",
     "description": "The list of locations.",
     "items": {
      "$ref": "Location"
     }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#locationsList.",
     "default": "mirror#locationsList"
       }
   }
     },
     "MenuItem": {
   "id": "MenuItem",
   "type": "object",
   "description": "A custom menu item that can be presented to the user by a timeline item.",
   "properties": {
       "action": {
     "type": "string",
     "description": "Controls the behavior when the user picks the menu option. Allowed values are:  \n- CUSTOM - Custom action set by the service. When the user selects this menuItem, the API triggers a notification to your callbackUrl with the userActions.type set to CUSTOM and the userActions.payload set to the ID of this menu item. This is the default value. \n- Built-in actions:  \n- REPLY - Initiate a reply to the timeline item using the voice recording UI. The creator attribute must be set in the timeline item for this menu to be available. \n- REPLY_ALL - Same behavior as REPLY. The original timeline item's recipients will be added to the reply item. \n- DELETE - Delete the timeline item. \n- SHARE - Share the timeline item with the available contacts. \n- READ_ALOUD - Read the timeline item's speakableText aloud; if this field is not set, read the text field; if none of those fields are set, this menu item is ignored.  \n- VOICE_CALL - Initiate a phone call using the timeline item's creator.phone_number attribute as recipient. \n- NAVIGATE - Navigate to the timeline item's location. \n- TOGGLE_PINNED - Toggle the isPinned state of the timeline item. \n- OPEN_URI - Open the payload of the menu item in the browser. \n- PLAY_VIDEO - Open the payload of the menu item in the Glass video player."
       },
         "id": {
     "type": "string",
     "description": "The ID for this menu item. This is generated by the application and is treated as an opaque token."
     },
         "payload": {
     "type": "string",
     "description": "A generic payload whose meaning changes depending on this MenuItem's action.  \n- When the action is OPEN_URI, the payload is the URL of the website to view. \n- When the action is PLAY_VIDEO, the payload is the streaming URL of the video"
     },
         "removeWhenSelected": {
     "type": "boolean",
     "description": "If set to true on a CUSTOM menu item, that item will be removed from the menu after it is selected."
     },
         "values": {
     "type": "array",
     "description": "For CUSTOM items, a list of values controlling the appearance of the menu item in each of its states. A value for the DEFAULT state must be provided. If the PENDING or CONFIRMED states are missing, they will not be shown.",
     "items": {
      "$ref": "MenuValue"
     }
     }
   }
     },
     "MenuValue": {
   "id": "MenuValue",
   "type": "object",
   "description": "A single value that is part of a MenuItem.",
   "properties": {
       "displayName": {
     "type": "string",
     "description": "The name to display for the menu item. If you specify this property for a built-in menu item, the default contextual voice command for that menu item is not shown."
       },
         "iconUrl": {
     "type": "string",
     "description": "URL of an icon to display with the menu item."
     },
         "state": {
     "type": "string",
     "description": "The state that this value applies to. Allowed values are:  \n- DEFAULT - Default value shown when displayed in the menuItems list. \n- PENDING - Value shown when the menuItem has been selected by the user but can still be cancelled. \n- CONFIRMED - Value shown when the menuItem has been selected by the user and can no longer be cancelled."
     }
   }
     },
     "Notification": {
   "id": "Notification",
   "type": "object",
   "description": "A notification delivered by the API.",
   "properties": {
       "collection": {
     "type": "string",
     "description": "The collection that generated the notification."
       },
         "itemId": {
     "type": "string",
     "description": "The ID of the item that generated the notification."
     },
         "operation": {
     "type": "string",
     "description": "The type of operation that generated the notification."
     },
         "userActions": {
     "type": "array",
     "description": "A list of actions taken by the user that triggered the notification.",
     "items": {
      "$ref": "UserAction"
     }
     },
       "userToken": {
     "type": "string",
     "description": "The user token provided by the service when it subscribed for notifications."
       },
         "verifyToken": {
     "type": "string",
     "description": "The secret verify token provided by the service when it subscribed for notifications."
     }
   }
     },
     "NotificationConfig": {
   "id": "NotificationConfig",
   "type": "object",
   "description": "Controls how notifications for a timeline item are presented to the user.",
   "properties": {
       "deliveryTime": {
     "type": "string",
     "description": "The time at which the notification should be delivered.",
     "format": "date-time"
       },
         "level": {
     "type": "string",
     "description": "Describes how important the notification is. Allowed values are:  \n- DEFAULT - Notifications of default importance. A chime will be played to alert users."
     }
   }
     },
     "Subscription": {
   "id": "Subscription",
   "type": "object",
   "description": "A subscription to events on a collection.",
   "properties": {
       "callbackUrl": {
     "type": "string",
     "description": "The URL where notifications should be delivered (must start with https://).",
     "annotations": {
      "required": [
       "mirror.subscriptions.insert",
       "mirror.subscriptions.update"
      ]
     }
       },
       "collection": {
     "type": "string",
     "description": "The collection to subscribe to. Allowed values are:  \n- timeline - Changes in the timeline including insertion, deletion, and updates. \n- locations - Location updates.",
     "annotations": {
      "required": [
       "mirror.subscriptions.insert",
       "mirror.subscriptions.update"
      ]
     }
       },
       "id": {
     "type": "string",
     "description": "The ID of the subscription."
       },
         "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#subscription.",
     "default": "mirror#subscription"
     },
         "notification": {
     "$ref": "Notification",
     "description": "Container object for notifications. This is not populated in the Subscription resource."
     },
         "operation": {
     "type": "array",
     "description": "A list of operations that should be subscribed to. An empty list indicates that all operations on the collection should be subscribed to. Allowed values are:  \n- UPDATE - The item has been updated. \n- INSERT - A new item has been inserted. \n- DELETE - The item has been deleted. \n- MENU_ACTION - A custom menu item has been triggered by the user.",
     "items": {
      "type": "string"
     }
     },
       "updated": {
     "type": "string",
     "description": "The time at which this subscription was last modified, formatted according to RFC 3339.",
     "format": "date-time"
       },
         "userToken": {
     "type": "string",
     "description": "An opaque token sent to the subscriber in notifications so that it can determine the ID of the user."
     },
         "verifyToken": {
     "type": "string",
     "description": "A secret token sent to the subscriber in notifications so that it can verify that the notification was generated by Google."
     }
   }
     },
     "SubscriptionsListResponse": {
   "id": "SubscriptionsListResponse",
   "type": "object",
   "description": "A list of Subscriptions. This is the response from the server to GET requests on the subscription collection.",
   "properties": {
       "items": {
     "type": "array",
     "description": "The list of subscriptions.",
     "items": {
      "$ref": "Subscription"
     }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#subscriptionsList.",
     "default": "mirror#subscriptionsList"
       }
   }
     },
     "TimelineItem": {
   "id": "TimelineItem",
   "type": "object",
   "description": "Each item in the user's timeline is represented as a TimelineItem JSON structure, described below.",
   "properties": {
       "attachments": {
     "type": "array",
     "description": "A list of media attachments associated with this item. As a convenience, you can refer to attachments in your HTML payloads with the attachment or cid scheme. For example:  \n- attachment: \u003cimg src=\"attachment:attachment_index\"\u003e where attachment_index is the 0-based index of this array. \n- cid: \u003cimg src=\"cid:attachment_id\"\u003e where attachment_id is the ID of the attachment.",
     "items": {
      "$ref": "Attachment"
     }
       },
       "bundleId": {
     "type": "string",
     "description": "The bundle ID for this item. Services can specify a bundleId to group many items together. They appear under a single top-level item on the device."
       },
         "canonicalUrl": {
     "type": "string",
     "description": "A canonical URL pointing to the canonical/high quality version of the data represented by the timeline item."
     },
         "created": {
     "type": "string",
     "description": "The time at which this item was created, formatted according to RFC 3339.",
     "format": "date-time"
     },
         "creator": {
     "$ref": "Contact",
     "description": "The user or group that created this item."
     },
         "displayTime": {
     "type": "string",
     "description": "The time that should be displayed when this item is viewed in the timeline, formatted according to RFC 3339. This user's timeline is sorted chronologically on display time, so this will also determine where the item is displayed in the timeline. If not set by the service, the display time defaults to the updated time.",
     "format": "date-time"
     },
         "etag": {
     "type": "string",
     "description": "ETag for this item."
     },
         "html": {
     "type": "string",
     "description": "HTML content for this item. If both text and html are provided for an item, the html will be rendered in the timeline.\nAllowed HTML elements - You can use these elements in your timeline cards.\n \n- Headers: h1, h2, h3, h4, h5, h6 \n- Images: img \n- Lists: li, ol, ul \n- HTML5 semantics: article, aside, details, figure, figcaption, footer, header, nav, section, summary, time \n- Structural: blockquote, br, div, hr, p, span \n- Style: b, big, center, em, i, u, s, small, strike, strong, style, sub, sup \n- Tables: table, tbody, td, tfoot, th, thead, tr  \nBlocked HTML elements: These elements and their contents are removed from HTML payloads.\n \n- Document headers: head, title \n- Embeds: audio, embed, object, source, video \n- Frames: frame, frameset \n- Scripting: applet, script  \nOther elements: Any elements that aren't listed are removed, but their contents are preserved."
     },
         "id": {
     "type": "string",
     "description": "The ID of the timeline item. This is unique within a user's timeline."
     },
         "inReplyTo": {
     "type": "string",
     "description": "If this item was generated as a reply to another item, this field will be set to the ID of the item being replied to. This can be used to attach a reply to the appropriate conversation or post."
     },
         "isBundleCover": {
     "type": "boolean",
     "description": "Whether this item is a bundle cover.\n\nIf an item is marked as a bundle cover, it will be the entry point to the bundle of items that have the same bundleId as that item. It will be shown only on the main timeline — not within the opened bundle.\n\nOn the main timeline, items that are shown are:  \n- Items that have isBundleCover set to true  \n- Items that do not have a bundleId  In a bundle sub-timeline, items that are shown are:  \n- Items that have the bundleId in question AND isBundleCover set to false"
     },
         "isDeleted": {
     "type": "boolean",
     "description": "When true, indicates this item is deleted, and only the ID property is set."
     },
         "isPinned": {
     "type": "boolean",
     "description": "When true, indicates this item is pinned, which means it's grouped alongside \"active\" items like navigation and hangouts, on the opposite side of the home screen from historical (non-pinned) timeline items. You can allow the user to toggle the value of this property with the TOGGLE_PINNED built-in menu item."
     },
         "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#timelineItem.",
     "default": "mirror#timelineItem"
     },
         "location": {
     "$ref": "Location",
     "description": "The geographic location associated with this item."
     },
         "menuItems": {
     "type": "array",
     "description": "A list of menu items that will be presented to the user when this item is selected in the timeline.",
     "items": {
      "$ref": "MenuItem"
     }
     },
       "notification": {
     "$ref": "NotificationConfig",
     "description": "Controls how notifications for this item are presented on the device. If this is missing, no notification will be generated."
       },
         "pinScore": {
     "type": "integer",
     "description": "For pinned items, this determines the order in which the item is displayed in the timeline, with a higher score appearing closer to the clock. Note: setting this field is currently not supported.",
     "format": "int32"
     },
         "recipients": {
     "type": "array",
     "description": "A list of users or groups that this item has been shared with.",
     "items": {
      "$ref": "Contact"
     }
     },
       "selfLink": {
     "type": "string",
     "description": "A URL that can be used to retrieve this item."
       },
         "sourceItemId": {
     "type": "string",
     "description": "Opaque string you can use to map a timeline item to data in your own service."
     },
         "speakableText": {
     "type": "string",
     "description": "The speakable version of the content of this item. Along with the READ_ALOUD menu item, use this field to provide text that would be clearer when read aloud, or to provide extended information to what is displayed visually on Glass.\n\nGlassware should also specify the speakableType field, which will be spoken before this text in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification."
     },
         "speakableType": {
     "type": "string",
     "description": "A speakable description of the type of this item. This will be announced to the user prior to reading the content of the item in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification.\n\nThis should be a short, simple noun phrase such as \"Email\", \"Text message\", or \"Daily Planet News Update\".\n\nGlassware are encouraged to populate this field for every timeline item, even if the item does not contain speakableText or text so that the user can learn the type of the item without looking at the screen."
     },
         "text": {
     "type": "string",
     "description": "Text content of this item."
     },
         "title": {
     "type": "string",
     "description": "The title of this item."
     },
         "updated": {
     "type": "string",
     "description": "The time at which this item was last modified, formatted according to RFC 3339.",
     "format": "date-time"
     }
   }
     },
     "TimelineListResponse": {
   "id": "TimelineListResponse",
   "type": "object",
   "description": "A list of timeline items. This is the response from the server to GET requests on the timeline collection.",
   "properties": {
       "items": {
     "type": "array",
     "description": "Items in the timeline.",
     "items": {
      "$ref": "TimelineItem"
     }
       },
       "kind": {
     "type": "string",
     "description": "The type of resource. This is always mirror#timeline.",
     "default": "mirror#timeline"
       },
         "nextPageToken": {
     "type": "string",
     "description": "The next page token. Provide this as the pageToken parameter in the request to retrieve the next page of results."
     }
   }
     },
     "UserAction": {
   "id": "UserAction",
   "type": "object",
   "description": "Represents an action taken by the user that triggered a notification.",
   "properties": {
       "payload": {
     "type": "string",
     "description": "An optional payload for the action.\n\nFor actions of type CUSTOM, this is the ID of the custom menu item that was selected."
       },
         "type": {
     "type": "string",
     "description": "The type of action. The value of this can be:  \n- SHARE - the user shared an item. \n- REPLY - the user replied to an item. \n- REPLY_ALL - the user replied to all recipients of an item. \n- CUSTOM - the user selected a custom menu item on the timeline item. \n- DELETE - the user deleted the item. \n- PIN - the user pinned the item. \n- UNPIN - the user unpinned the item. \n- LAUNCH - the user initiated a voice command.  In the future, additional types may be added. UserActions with unrecognized types should be ignored."
     }
   }
     }
 },
 "resources": {
     "contacts": {
         "methods": {
             "delete": {
     "id": "mirror.contacts.delete",
     "path": "contacts/{id}",
     "httpMethod": "DELETE",
     "description": "Deletes a contact.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the contact.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ]
             },
     "get": {
     "id": "mirror.contacts.get",
     "path": "contacts/{id}",
     "httpMethod": "GET",
     "description": "Gets a single contact by ID.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the contact.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "response": {
      "$ref": "Contact"
  }
 },
             "insert": {
     "id": "mirror.contacts.insert",
     "path": "contacts",
     "httpMethod": "POST",
     "description": "Inserts a new contact.",
     "request": {
      "$ref": "Contact"
     },
          "response": {
      "$ref": "Contact"
      }
             },
             "list": {
     "id": "mirror.contacts.list",
     "path": "contacts",
     "httpMethod": "GET",
     "description": "Retrieves a list of contacts for the authenticated user.",
     "response": {
      "$ref": "ContactsListResponse"
     }
             },
             "patch": {
     "id": "mirror.contacts.patch",
     "path": "contacts/{id}",
     "httpMethod": "PATCH",
     "description": "Updates a contact in place. This method supports patch semantics.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the contact.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "request": {
      "$ref": "Contact"
  },
          "response": {
      "$ref": "Contact"
      }
             },
             "update": {
     "id": "mirror.contacts.update",
     "path": "contacts/{id}",
     "httpMethod": "PUT",
     "description": "Updates a contact in place.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the contact.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "request": {
      "$ref": "Contact"
  },
          "response": {
      "$ref": "Contact"
      }
             }
         }
     },
     "locations": {
         "methods": {
             "get": {
     "id": "mirror.locations.get",
     "path": "locations/{id}",
     "httpMethod": "GET",
     "description": "Gets a single location by ID.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the location or latest for the last known location.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "response": {
      "$ref": "Location"
  }
             },
             "list": {
     "id": "mirror.locations.list",
     "path": "locations",
     "httpMethod": "GET",
     "description": "Retrieves a list of locations for the user.",
     "response": {
      "$ref": "LocationsListResponse"
     }
             }
         }
     },
     "subscriptions": {
         "methods": {
             "delete": {
     "id": "mirror.subscriptions.delete",
     "path": "subscriptions/{id}",
     "httpMethod": "DELETE",
     "description": "Deletes a subscription.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the subscription.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ]
             },
     "insert": {
     "id": "mirror.subscriptions.insert",
     "path": "subscriptions",
     "httpMethod": "POST",
     "description": "Creates a new subscription.",
     "request": {
      "$ref": "Subscription"
     },
          "response": {
      "$ref": "Subscription"
      }
 },
             "list": {
     "id": "mirror.subscriptions.list",
     "path": "subscriptions",
     "httpMethod": "GET",
     "description": "Retrieves a list of subscriptions for the authenticated user and service.",
     "response": {
      "$ref": "SubscriptionsListResponse"
     }
             },
             "update": {
     "id": "mirror.subscriptions.update",
     "path": "subscriptions/{id}",
     "httpMethod": "PUT",
     "description": "Updates an existing subscription in place.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the subscription.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "request": {
      "$ref": "Subscription"
  },
          "response": {
      "$ref": "Subscription"
      }
             }
         }
     },
     "timeline": {
         "methods": {
             "delete": {
     "id": "mirror.timeline.delete",
     "path": "timeline/{id}",
     "httpMethod": "DELETE",
     "description": "Deletes a timeline item.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the timeline item.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ]
             },
     "get": {
     "id": "mirror.timeline.get",
     "path": "timeline/{id}",
     "httpMethod": "GET",
     "description": "Gets a single timeline item by ID.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the timeline item.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "response": {
      "$ref": "TimelineItem"
  }
 },
             "insert": {
     "id": "mirror.timeline.insert",
     "path": "timeline",
     "httpMethod": "POST",
     "description": "Inserts a new item into the timeline.",
     "request": {
      "$ref": "TimelineItem"
     },
          "response": {
      "$ref": "TimelineItem"
      },
     "supportsMediaUpload": true,
          "mediaUpload": {
      "accept": [
       "audio/*",
       "image/*",
       "video/*"
      ],
      "maxSize": "10MB",
       "protocols": {
           "simple": {
        "multipart": true,
        "path": "/upload/mirror/v1/timeline"
           },
            "resumable": {
        "multipart": true,
        "path": "/resumable/upload/mirror/v1/timeline"
        }
   }
      }
             },
             "list": {
     "id": "mirror.timeline.list",
     "path": "timeline",
     "httpMethod": "GET",
     "description": "Retrieves a list of timeline items for the authenticated user.",
     "parameters": {
         "bundleId": {
       "type": "string",
       "description": "If provided, only items with the given bundleId will be returned.",
       "location": "query"
         },
           "includeDeleted": {
       "type": "boolean",
       "description": "If true, tombstone records for deleted items will be returned.",
       "location": "query"
       },
           "maxResults": {
       "type": "integer",
       "description": "The maximum number of items to include in the response, used for paging.",
       "format": "uint32",
       "location": "query"
       },
           "orderBy": {
       "type": "string",
       "description": "Controls the order in which timeline items are returned.",
       "enum": [
        "displayTime",
        "writeTime"
       ],
       "enumDescriptions": [
        "Results will be ordered by displayTime (default). This is the same ordering as is used in the timeline on the device.",
        "Results will be ordered by the time at which they were last written to the data store."
       ],
       "location": "query"
       },
       "pageToken": {
       "type": "string",
       "description": "Token for the page of results to return.",
       "location": "query"
   },
           "pinnedOnly": {
       "type": "boolean",
       "description": "If true, only pinned items will be returned.",
       "location": "query"
       },
           "sourceItemId": {
       "type": "string",
       "description": "If provided, only items with the given sourceItemId will be returned.",
       "location": "query"
       }
     },
     "response": {
      "$ref": "TimelineListResponse"
     }
             },
             "patch": {
     "id": "mirror.timeline.patch",
     "path": "timeline/{id}",
     "httpMethod": "PATCH",
     "description": "Updates a timeline item in place. This method supports patch semantics.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the timeline item.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "request": {
      "$ref": "TimelineItem"
  },
          "response": {
      "$ref": "TimelineItem"
      }
             },
             "update": {
     "id": "mirror.timeline.update",
     "path": "timeline/{id}",
     "httpMethod": "PUT",
     "description": "Updates a timeline item in place.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the timeline item.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
      "request": {
      "$ref": "TimelineItem"
  },
          "response": {
      "$ref": "TimelineItem"
      },
     "supportsMediaUpload": true,
          "mediaUpload": {
      "accept": [
       "audio/*",
       "image/*",
       "video/*"
      ],
      "maxSize": "10MB",
       "protocols": {
           "simple": {
        "multipart": true,
        "path": "/upload/mirror/v1/timeline/{id}"
           },
            "resumable": {
        "multipart": true,
        "path": "/resumable/upload/mirror/v1/timeline/{id}"
        }
   }
      }
             }
         },
         "resources": {
             "attachments": {
                 "methods": {
                     "delete": {
       "id": "mirror.timeline.attachments.delete",
       "path": "timeline/{itemId}/attachments/{attachmentId}",
       "httpMethod": "DELETE",
       "description": "Deletes an attachment from a timeline item.",
       "parameters": {
           "attachmentId": {
         "type": "string",
         "description": "The ID of the attachment.",
         "required": true,
         "location": "path"
           },
             "itemId": {
         "type": "string",
         "description": "The ID of the timeline item the attachment belongs to.",
         "required": true,
         "location": "path"
         }
       },
       "parameterOrder": [
        "itemId",
        "attachmentId"
       ]
                     },
       "get": {
       "id": "mirror.timeline.attachments.get",
       "path": "timeline/{itemId}/attachments/{attachmentId}",
       "httpMethod": "GET",
       "description": "Retrieves an attachment on a timeline item by item ID and attachment ID.",
       "parameters": {
           "attachmentId": {
         "type": "string",
         "description": "The ID of the attachment.",
         "required": true,
         "location": "path"
           },
             "itemId": {
         "type": "string",
         "description": "The ID of the timeline item the attachment belongs to.",
         "required": true,
         "location": "path"
         }
       },
       "parameterOrder": [
        "itemId",
        "attachmentId"
       ],
        "response": {
        "$ref": "Attachment"
    },
       "supportsMediaDownload": true
   },
       "insert": {
       "id": "mirror.timeline.attachments.insert",
       "path": "timeline/{itemId}/attachments",
       "httpMethod": "POST",
       "description": "Adds a new attachment to a timeline item.",
       "parameters": {
           "itemId": {
         "type": "string",
         "description": "The ID of the timeline item the attachment belongs to.",
         "required": true,
         "location": "path"
           }
       },
       "parameterOrder": [
        "itemId"
       ],
        "response": {
        "$ref": "Attachment"
    },
       "supportsMediaUpload": true,
            "mediaUpload": {
        "accept": [
         "audio/*",
         "image/*",
         "video/*"
        ],
        "maxSize": "10MB",
         "protocols": {
             "simple": {
          "multipart": true,
          "path": "/upload/mirror/v1/timeline/{itemId}/attachments"
             },
              "resumable": {
          "multipart": true,
          "path": "/resumable/upload/mirror/v1/timeline/{itemId}/attachments"
          }
     }
        }
   },
                     "list": {
       "id": "mirror.timeline.attachments.list",
       "path": "timeline/{itemId}/attachments",
       "httpMethod": "GET",
       "description": "Returns a list of attachments for a timeline item.",
       "parameters": {
           "itemId": {
         "type": "string",
         "description": "The ID of the timeline item whose attachments should be listed.",
         "required": true,
         "location": "path"
           }
       },
       "parameterOrder": [
        "itemId"
       ],
        "response": {
        "$ref": "AttachmentsListResponse"
    }
                     }
                 }
             }
         }
     }
 }
}

EOF

$apis{oauth2}{v2} = <<'EOF';
{
 "kind": "discovery#restDescription",
 "etag": "\"DGgqtFnjgu83tuwvvVNNUhOiHWk/610kr4ZlL53w3blZCnftCmKVFqI\"",
 "discoveryVersion": "v1",
 "id": "oauth2:v2",
 "name": "oauth2",
 "version": "v2",
 "title": "Google OAuth2 API",
 "description": "Lets you access OAuth2 protocol related APIs.",
 "ownerDomain": "google.com",
 "ownerName": "Google",
 "icons": {
  "x16": "http://www.google.com/images/icons/product/search-16.gif",
  "x32": "http://www.google.com/images/icons/product/search-32.gif"
 },
 "documentationLink": "https://developers.google.com/accounts/docs/OAuth2",
 "protocol": "rest",
 "baseUrl": "https://www.googleapis.com/",
 "basePath": "/",
 "rootUrl": "https://www.googleapis.com/",
 "servicePath": "",
 "batchPath": "batch",
      "parameters": {
          "alt": {
   "type": "string",
   "description": "Data format for the response.",
   "default": "json",
   "enum": [
    "json"
   ],
   "enumDescriptions": [
    "Responses with Content-Type of application/json"
   ],
   "location": "query"
          },
   "fields": {
   "type": "string",
   "description": "Selector specifying which fields to include in a partial response.",
   "location": "query"
},
       "key": {
   "type": "string",
   "description": "API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.",
   "location": "query"
   },
       "oauth_token": {
   "type": "string",
   "description": "OAuth 2.0 token for the current user.",
   "location": "query"
   },
       "prettyPrint": {
   "type": "boolean",
   "description": "Returns response with indentations and line breaks.",
   "default": "true",
   "location": "query"
   },
       "quotaUser": {
   "type": "string",
   "description": "Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters. Overrides userIp if both are provided.",
   "location": "query"
   },
       "userIp": {
   "type": "string",
   "description": "IP address of the site where the request originates. Use this if you want to enforce per-user limits.",
   "location": "query"
   }
  },
 "auth": {
     "oauth2": {
         "scopes": {
             "https://www.googleapis.com/auth/plus.login": {
     "description": "Know your basic profile info and list of people in your circles."
             },
         "https://www.googleapis.com/auth/plus.me": {
     "description": "Know who you are on Google"
     },
         "https://www.googleapis.com/auth/userinfo.email": {
     "description": "View your email address"
     },
         "https://www.googleapis.com/auth/userinfo.profile": {
     "description": "View basic information about your account"
     }
         }
     }
 },
 "schemas": {
     "Tokeninfo": {
   "id": "Tokeninfo",
   "type": "object",
   "properties": {
       "access_type": {
     "type": "string",
     "description": "The access type granted with this token. It can be offline or online."
       },
         "audience": {
     "type": "string",
     "description": "Who is the intended audience for this token. In general the same as issued_to."
     },
         "email": {
     "type": "string",
     "description": "The email address of the user. Present only if the email scope is present in the request."
     },
         "expires_in": {
     "type": "integer",
     "description": "The expiry time of the token, as number of seconds left until expiry.",
     "format": "int32"
     },
         "issued_to": {
     "type": "string",
     "description": "To whom was the token issued to. In general the same as audience."
     },
         "scope": {
     "type": "string",
     "description": "The space separated list of scopes granted to this token."
     },
         "user_id": {
     "type": "string",
     "description": "The Gaia obfuscated user id."
     },
         "verified_email": {
     "type": "boolean",
     "description": "Boolean flag which is true if the email address is verified. Present only if the email scope is present in the request."
     }
   }
     },
     "Userinfo": {
   "id": "Userinfo",
   "type": "object",
   "properties": {
       "email": {
     "type": "string",
     "description": "The user's email address."
       },
         "family_name": {
     "type": "string",
     "description": "The user's last name."
     },
         "gender": {
     "type": "string",
     "description": "The user's gender."
     },
         "given_name": {
     "type": "string",
     "description": "The user's first name."
     },
         "hd": {
     "type": "string",
     "description": "The hosted domain e.g. example.com if the user is Google apps user."
     },
         "id": {
     "type": "string",
     "description": "The focus obfuscated gaia id of the user."
     },
         "link": {
     "type": "string",
     "description": "URL of the profile page."
     },
         "locale": {
     "type": "string",
     "description": "The user's default locale."
     },
         "name": {
     "type": "string",
     "description": "The user's full name."
     },
         "picture": {
     "type": "string",
     "description": "URL of the user's picture image."
     },
         "timezone": {
     "type": "string",
     "description": "The user's default timezone."
     },
         "verified_email": {
     "type": "boolean",
     "description": "Boolean flag which is true if the email address is verified."
     }
   }
     }
 },
 "methods": {
     "tokeninfo": {
   "id": "oauth2.tokeninfo",
   "path": "oauth2/v2/tokeninfo",
   "httpMethod": "POST",
   "parameters": {
       "access_token": {
     "type": "string",
     "location": "query"
       },
         "id_token": {
     "type": "string",
     "location": "query"
     }
   },
   "response": {
    "$ref": "Tokeninfo"
   }
     }
 },
 "resources": {
     "userinfo": {
         "methods": {
             "get": {
     "id": "oauth2.userinfo.get",
     "path": "oauth2/v2/userinfo",
     "httpMethod": "GET",
     "response": {
      "$ref": "Userinfo"
     },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me",
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/userinfo.profile"
     ]
             }
         },
         "resources": {
             "v2": {
                 "resources": {
                     "me": {
                         "methods": {
                             "get": {
         "id": "oauth2.userinfo.v2.me.get",
         "path": "userinfo/v2/me",
         "httpMethod": "GET",
         "response": {
          "$ref": "Userinfo"
         },
         "scopes": [
          "https://www.googleapis.com/auth/plus.login",
          "https://www.googleapis.com/auth/plus.me",
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/userinfo.profile"
         ]
                             }
                         }
                     }
                 }
             }
         }
     }
 }
}

EOF

$apis{plus}{v1} = <<'EOF';
{
 "kind": "discovery#restDescription",
 "etag": "\"DGgqtFnjgu83tuwvvVNNUhOiHWk/DMGlXi8jhJTMEmr-VAaiIhmcCGI\"",
 "discoveryVersion": "v1",
 "id": "plus:v1",
 "name": "plus",
 "version": "v1",
 "title": "Google+ API",
 "description": "The Google+ API enables developers to build on top of the Google+ platform.",
 "ownerDomain": "google.com",
 "ownerName": "Google",
 "icons": {
  "x16": "http://www.google.com/images/icons/product/gplus-16.png",
  "x32": "http://www.google.com/images/icons/product/gplus-32.png"
 },
 "documentationLink": "https://developers.google.com/+/api/",
 "protocol": "rest",
 "baseUrl": "https://www.googleapis.com/plus/v1/",
 "basePath": "/plus/v1/",
 "rootUrl": "https://www.googleapis.com/",
 "servicePath": "plus/v1/",
 "batchPath": "batch",
      "parameters": {
          "alt": {
   "type": "string",
   "description": "Data format for the response.",
   "default": "json",
   "enum": [
    "json"
   ],
   "enumDescriptions": [
    "Responses with Content-Type of application/json"
   ],
   "location": "query"
          },
   "fields": {
   "type": "string",
   "description": "Selector specifying which fields to include in a partial response.",
   "location": "query"
},
       "key": {
   "type": "string",
   "description": "API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.",
   "location": "query"
   },
       "oauth_token": {
   "type": "string",
   "description": "OAuth 2.0 token for the current user.",
   "location": "query"
   },
       "prettyPrint": {
   "type": "boolean",
   "description": "Returns response with indentations and line breaks.",
   "default": "true",
   "location": "query"
   },
       "quotaUser": {
   "type": "string",
   "description": "Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters. Overrides userIp if both are provided.",
   "location": "query"
   },
       "userIp": {
   "type": "string",
   "description": "IP address of the site where the request originates. Use this if you want to enforce per-user limits.",
   "location": "query"
   }
  },
 "auth": {
     "oauth2": {
         "scopes": {
             "https://www.googleapis.com/auth/plus.login": {
     "description": "Know your basic profile info and list of people in your circles."
             },
         "https://www.googleapis.com/auth/plus.me": {
     "description": "Know who you are on Google"
     }
         }
     }
 },
 "schemas": {
     "Acl": {
   "id": "Acl",
   "type": "object",
   "properties": {
       "description": {
     "type": "string",
     "description": "Description of the access granted, suitable for display."
       },
         "items": {
     "type": "array",
     "description": "The list of access entries.",
     "items": {
      "$ref": "PlusAclentryResource"
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a collection of access controls. Value: \"plus#acl\".",
     "default": "plus#acl"
       }
   }
     },
     "Activity": {
   "id": "Activity",
   "type": "object",
   "properties": {
       "access": {
     "$ref": "Acl",
     "description": "Identifies who has access to see this activity."
       },
         "actor": {
     "type": "object",
     "description": "The person who performed this activity.",
     "properties": {
         "displayName": {
       "type": "string",
       "description": "The name of the actor, suitable for display."
         },
           "id": {
       "type": "string",
       "description": "The ID of the actor's Person resource."
       },
           "image": {
       "type": "object",
       "description": "The image representation of the actor.",
       "properties": {
           "url": {
         "type": "string",
         "description": "The URL of the actor's profile photo. To resize the image and crop it to a square, append the query string ?sz=x, where x is the dimension in pixels of each side."
           }
       }
       },
         "name": {
       "type": "object",
       "description": "An object representation of the individual components of name.",
       "properties": {
           "familyName": {
         "type": "string",
         "description": "The family name (\"last name\") of the actor."
           },
             "givenName": {
         "type": "string",
         "description": "The given name (\"first name\") of the actor."
         }
       }
         },
         "url": {
       "type": "string",
       "description": "The link to the actor's Google profile."
         }
     }
     },
       "address": {
     "type": "string",
     "description": "Street address where this activity occurred."
       },
         "annotation": {
     "type": "string",
     "description": "Additional content added by the person who shared this activity, applicable only when resharing an activity."
     },
         "crosspostSource": {
     "type": "string",
     "description": "If this activity is a crosspost from another system, this property specifies the ID of the original activity."
     },
         "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
     },
         "geocode": {
     "type": "string",
     "description": "Latitude and longitude where this activity occurred. Format is latitude followed by longitude, space separated."
     },
         "id": {
     "type": "string",
     "description": "The ID of this activity."
     },
         "kind": {
     "type": "string",
     "description": "Identifies this resource as an activity. Value: \"plus#activity\".",
     "default": "plus#activity"
     },
         "location": {
     "$ref": "Place",
     "description": "The location where this activity occurred."
     },
         "object": {
     "type": "object",
     "description": "The object of this activity.",
     "properties": {
         "actor": {
       "type": "object",
       "description": "If this activity's object is itself another activity, such as when a person reshares an activity, this property specifies the original activity's actor.",
       "properties": {
           "displayName": {
         "type": "string",
         "description": "The original actor's name, which is suitable for display."
           },
             "id": {
         "type": "string",
         "description": "ID of the original actor."
         },
             "image": {
         "type": "object",
         "description": "The image representation of the original actor.",
         "properties": {
             "url": {
           "type": "string",
           "description": "A URL that points to a thumbnail photo of the original actor."
             }
         }
         },
           "url": {
         "type": "string",
         "description": "A link to the original actor's Google profile."
           }
       }
         },
         "attachments": {
       "type": "array",
       "description": "The media objects attached to this activity.",
       "items": {
        "type": "object",
        "properties": {
            "content": {
          "type": "string",
          "description": "If the attachment is an article, this property contains a snippet of text from the article. It can also include descriptions for other types."
            },
              "displayName": {
          "type": "string",
          "description": "The title of the attachment, such as a photo caption or an article title."
          },
              "embed": {
          "type": "object",
          "description": "If the attachment is a video, the embeddable link.",
          "properties": {
              "type": {
            "type": "string",
            "description": "Media type of the link."
              },
                "url": {
            "type": "string",
            "description": "URL of the link."
            }
          }
          },
            "fullImage": {
          "type": "object",
          "description": "The full image URL for photo attachments.",
          "properties": {
              "height": {
            "type": "integer",
            "description": "The height, in pixels, of the linked resource.",
            "format": "uint32"
              },
                "type": {
            "type": "string",
            "description": "Media type of the link."
            },
                "url": {
            "type": "string",
            "description": "URL of the image."
            },
                "width": {
            "type": "integer",
            "description": "The width, in pixels, of the linked resource.",
            "format": "uint32"
            }
          }
            },
            "id": {
          "type": "string",
          "description": "The ID of the attachment."
            },
              "image": {
          "type": "object",
          "description": "The preview image for photos or videos.",
          "properties": {
              "height": {
            "type": "integer",
            "description": "The height, in pixels, of the linked resource.",
            "format": "uint32"
              },
                "type": {
            "type": "string",
            "description": "Media type of the link."
            },
                "url": {
            "type": "string",
            "description": "Image URL."
            },
                "width": {
            "type": "integer",
            "description": "The width, in pixels, of the linked resource.",
            "format": "uint32"
            }
          }
          },
            "objectType": {
          "type": "string",
          "description": "The type of media object. Possible values include, but are not limited to, the following values:  \n- \"photo\" - A photo. \n- \"album\" - A photo album. \n- \"video\" - A video. \n- \"article\" - An article, specified by a link."
            },
              "thumbnails": {
          "type": "array",
          "description": "If the attachment is an album, this property is a list of potential additional thumbnails from the album.",
          "items": {
           "type": "object",
           "properties": {
               "description": {
             "type": "string",
             "description": "Potential name of the thumbnail."
               },
                 "image": {
             "type": "object",
             "description": "Image resource.",
             "properties": {
                 "height": {
               "type": "integer",
               "description": "The height, in pixels, of the linked resource.",
               "format": "uint32"
                 },
                   "type": {
               "type": "string",
               "description": "Media type of the link."
               },
                   "url": {
               "type": "string",
               "description": "Image url."
               },
                   "width": {
               "type": "integer",
               "description": "The width, in pixels, of the linked resource.",
               "format": "uint32"
               }
             }
             },
               "url": {
             "type": "string",
             "description": "URL of the webpage containing the image."
               }
           }
          }
          },
            "url": {
          "type": "string",
          "description": "The link to the attachment, which should be of type text/html."
            }
        }
       }
         },
         "content": {
       "type": "string",
       "description": "The HTML-formatted content, which is suitable for display."
         },
           "id": {
       "type": "string",
       "description": "The ID of the object. When resharing an activity, this is the ID of the activity that is being reshared."
       },
           "objectType": {
       "type": "string",
       "description": "The type of the object. Possible values include, but are not limited to, the following values:  \n- \"note\" - Textual content. \n- \"activity\" - A Google+ activity."
       },
           "originalContent": {
       "type": "string",
       "description": "The content (text) as provided by the author, which is stored without any HTML formatting. When creating or updating an activity, this value must be supplied as plain text in the request."
       },
           "plusoners": {
       "type": "object",
       "description": "People who +1'd this activity.",
       "properties": {
           "selfLink": {
         "type": "string",
         "description": "The URL for the collection of people who +1'd this activity."
           },
             "totalItems": {
         "type": "integer",
         "description": "Total number of people who +1'd this activity.",
         "format": "uint32"
         }
       }
       },
         "replies": {
       "type": "object",
       "description": "Comments in reply to this activity.",
       "properties": {
           "selfLink": {
         "type": "string",
         "description": "The URL for the collection of comments in reply to this activity."
           },
             "totalItems": {
         "type": "integer",
         "description": "Total number of comments on this activity.",
         "format": "uint32"
         }
       }
         },
         "resharers": {
       "type": "object",
       "description": "People who reshared this activity.",
       "properties": {
           "selfLink": {
         "type": "string",
         "description": "The URL for the collection of resharers."
           },
             "totalItems": {
         "type": "integer",
         "description": "Total number of people who reshared this activity.",
         "format": "uint32"
         }
       }
         },
         "url": {
       "type": "string",
       "description": "The URL that points to the linked resource."
         }
     }
     },
       "placeId": {
     "type": "string",
     "description": "ID of the place where this activity occurred."
       },
         "placeName": {
     "type": "string",
     "description": "Name of the place where this activity occurred."
     },
         "provider": {
     "type": "object",
     "description": "The service provider that initially published this activity.",
     "properties": {
         "title": {
       "type": "string",
       "description": "Name of the service provider."
         }
     }
     },
       "published": {
     "type": "string",
     "description": "The time at which this activity was initially published. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
       },
         "radius": {
     "type": "string",
     "description": "Radius, in meters, of the region where this activity occurred, centered at the latitude and longitude identified in geocode."
     },
         "title": {
     "type": "string",
     "description": "Title of this activity."
     },
         "updated": {
     "type": "string",
     "description": "The time at which this activity was last updated. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
     },
         "url": {
     "type": "string",
     "description": "The link to this activity."
     },
         "verb": {
     "type": "string",
     "description": "This activity's verb, which indicates the action that was performed. Possible values include, but are not limited to, the following values:  \n- \"post\" - Publish content to the stream. \n- \"share\" - Reshare an activity."
     }
   }
     },
     "ActivityFeed": {
   "id": "ActivityFeed",
   "type": "object",
   "properties": {
       "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
       },
         "id": {
     "type": "string",
     "description": "The ID of this collection of activities. Deprecated."
     },
         "items": {
     "type": "array",
     "description": "The activities in this page of results.",
     "items": {
      "$ref": "Activity"
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a collection of activities. Value: \"plus#activityFeed\".",
     "default": "plus#activityFeed"
       },
         "nextLink": {
     "type": "string",
     "description": "Link to the next page of activities."
     },
         "nextPageToken": {
     "type": "string",
     "description": "The continuation token, which is used to page through large result sets. Provide this value in a subsequent request to return the next page of results."
     },
         "selfLink": {
     "type": "string",
     "description": "Link to this activity resource."
     },
         "title": {
     "type": "string",
     "description": "The title of this collection of activities, which is a truncated portion of the content."
     },
         "updated": {
     "type": "string",
     "description": "The time at which this collection of activities was last updated. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
     }
   }
     },
     "Comment": {
   "id": "Comment",
   "type": "object",
   "properties": {
       "actor": {
     "type": "object",
     "description": "The person who posted this comment.",
     "properties": {
         "displayName": {
       "type": "string",
       "description": "The name of this actor, suitable for display."
         },
           "id": {
       "type": "string",
       "description": "The ID of the actor."
       },
           "image": {
       "type": "object",
       "description": "The image representation of this actor.",
       "properties": {
           "url": {
         "type": "string",
         "description": "The URL of the actor's profile photo. To resize the image and crop it to a square, append the query string ?sz=x, where x is the dimension in pixels of each side."
           }
       }
       },
         "url": {
       "type": "string",
       "description": "A link to the Person resource for this actor."
         }
     }
       },
       "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
       },
         "id": {
     "type": "string",
     "description": "The ID of this comment."
     },
         "inReplyTo": {
     "type": "array",
     "description": "The activity this comment replied to.",
     "items": {
      "type": "object",
      "properties": {
          "id": {
        "type": "string",
        "description": "The ID of the activity."
          },
            "url": {
        "type": "string",
        "description": "The URL of the activity."
        }
      }
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a comment. Value: \"plus#comment\".",
     "default": "plus#comment"
       },
         "object": {
     "type": "object",
     "description": "The object of this comment.",
     "properties": {
         "content": {
       "type": "string",
       "description": "The HTML-formatted content, suitable for display."
         },
           "objectType": {
       "type": "string",
       "description": "The object type of this comment. Possible values are:  \n- \"comment\" - A comment in reply to an activity.",
       "default": "comment"
       },
           "originalContent": {
       "type": "string",
       "description": "The content (text) as provided by the author, stored without any HTML formatting. When creating or updating a comment, this value must be supplied as plain text in the request."
       }
     }
     },
       "plusoners": {
     "type": "object",
     "description": "People who +1'd this comment.",
     "properties": {
         "totalItems": {
       "type": "integer",
       "description": "Total number of people who +1'd this comment.",
       "format": "uint32"
         }
     }
       },
       "published": {
     "type": "string",
     "description": "The time at which this comment was initially published. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
       },
         "selfLink": {
     "type": "string",
     "description": "Link to this comment resource."
     },
         "updated": {
     "type": "string",
     "description": "The time at which this comment was last updated. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
     },
         "verb": {
     "type": "string",
     "description": "This comment's verb, indicating what action was performed. Possible values are:  \n- \"post\" - Publish content to the stream.",
     "default": "post"
     }
   }
     },
     "CommentFeed": {
   "id": "CommentFeed",
   "type": "object",
   "properties": {
       "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
       },
         "id": {
     "type": "string",
     "description": "The ID of this collection of comments."
     },
         "items": {
     "type": "array",
     "description": "The comments in this page of results.",
     "items": {
      "$ref": "Comment"
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a collection of comments. Value: \"plus#commentFeed\".",
     "default": "plus#commentFeed"
       },
         "nextLink": {
     "type": "string",
     "description": "Link to the next page of activities."
     },
         "nextPageToken": {
     "type": "string",
     "description": "The continuation token, which is used to page through large result sets. Provide this value in a subsequent request to return the next page of results."
     },
         "title": {
     "type": "string",
     "description": "The title of this collection of comments."
     },
         "updated": {
     "type": "string",
     "description": "The time at which this collection of comments was last updated. Formatted as an RFC 3339 timestamp.",
     "format": "date-time"
     }
   }
     },
     "ItemScope": {
   "id": "ItemScope",
   "type": "object",
   "properties": {
       "about": {
     "$ref": "ItemScope",
     "description": "The subject matter of the content."
       },
         "additionalName": {
     "type": "array",
     "description": "An additional name for a Person, can be used for a middle name.",
     "items": {
      "type": "string"
     }
     },
       "address": {
     "$ref": "ItemScope",
     "description": "Postal address."
       },
         "addressCountry": {
     "type": "string",
     "description": "Address country."
     },
         "addressLocality": {
     "type": "string",
     "description": "Address locality."
     },
         "addressRegion": {
     "type": "string",
     "description": "Address region."
     },
         "associated_media": {
     "type": "array",
     "description": "The encoding.",
     "items": {
      "$ref": "ItemScope"
     }
     },
       "attendeeCount": {
     "type": "integer",
     "description": "Number of attendees.",
     "format": "int32"
       },
         "attendees": {
     "type": "array",
     "description": "A person attending the event.",
     "items": {
      "$ref": "ItemScope"
     }
     },
       "audio": {
     "$ref": "ItemScope",
     "description": "From http://schema.org/MusicRecording, the audio file."
       },
         "author": {
     "type": "array",
     "description": "The person or persons who created this result. In the example of restaurant reviews, this might be the reviewer's name.",
     "items": {
      "$ref": "ItemScope"
     }
     },
       "bestRating": {
     "type": "string",
     "description": "Best possible rating value that a result might obtain. This property defines the upper bound for the ratingValue. For example, you might have a 5 star rating scale, you would provide 5 as the value for this property."
       },
         "birthDate": {
     "type": "string",
     "description": "Date of birth."
     },
         "byArtist": {
     "$ref": "ItemScope",
     "description": "From http://schema.org/MusicRecording, the artist that performed this recording."
     },
         "caption": {
     "type": "string",
     "description": "The caption for this object."
     },
         "contentSize": {
     "type": "string",
     "description": "File size in (mega/kilo) bytes."
     },
         "contentUrl": {
     "type": "string",
     "description": "Actual bytes of the media object, for example the image file or video file."
     },
         "contributor": {
     "type": "array",
     "description": "A list of contributors to this result.",
     "items": {
      "$ref": "ItemScope"
     }
     },
       "dateCreated": {
     "type": "string",
     "description": "The date the result was created such as the date that a review was first created."
       },
         "dateModified": {
     "type": "string",
     "description": "The date the result was last modified such as the date that a review was last edited."
     },
         "datePublished": {
     "type": "string",
     "description": "The initial date that the result was published. For example, a user writes a comment on a blog, which has a result.dateCreated of when they submit it. If the blog users comment moderation, the result.datePublished value would match the date when the owner approved the message."
     },
         "description": {
     "type": "string",
     "description": "The string that describes the content of the result."
     },
         "duration": {
     "type": "string",
     "description": "The duration of the item (movie, audio recording, event, etc.) in ISO 8601 date format."
     },
         "embedUrl": {
     "type": "string",
     "description": "A URL pointing to a player for a specific video. In general, this is the information in the src element of an embed tag and should not be the same as the content of the loc tag."
     },
         "endDate": {
     "type": "string",
     "description": "The end date and time of the event (in ISO 8601 date format)."
     },
         "familyName": {
     "type": "string",
     "description": "Family name. This property can be used with givenName instead of the name property."
     },
         "gender": {
     "type": "string",
     "description": "Gender of the person."
     },
         "geo": {
     "$ref": "ItemScope",
     "description": "Geo coordinates."
     },
         "givenName": {
     "type": "string",
     "description": "Given name. This property can be used with familyName instead of the name property."
     },
         "height": {
     "type": "string",
     "description": "The height of the media object."
     },
         "id": {
     "type": "string",
     "description": "An identifier for the target. Your app can choose how to identify targets. The target.id is required if you are writing an activity that does not have a corresponding web page or target.url property."
     },
         "image": {
     "type": "string",
     "description": "A URL to the image that represents this result. For example, if a user writes a review of a restaurant and attaches a photo of their meal, you might use that photo as the result.image."
     },
         "inAlbum": {
     "$ref": "ItemScope",
     "description": "From http://schema.org/MusicRecording, which album a song is in."
     },
         "kind": {
     "type": "string",
     "description": "Identifies this resource as an itemScope.",
     "default": "plus#itemScope"
     },
         "latitude": {
     "type": "number",
     "description": "Latitude.",
     "format": "double"
     },
         "location": {
     "$ref": "ItemScope",
     "description": "The location of the event or organization."
     },
         "longitude": {
     "type": "number",
     "description": "Longitude.",
     "format": "double"
     },
         "name": {
     "type": "string",
     "description": "The name of the result. In the example of a restaurant review, this might be the summary the user gave their review such as \"Great ambiance, but overpriced.\""
     },
         "partOfTVSeries": {
     "$ref": "ItemScope",
     "description": "Property of http://schema.org/TVEpisode indicating which series the episode belongs to."
     },
         "performers": {
     "type": "array",
     "description": "The main performer or performers of the event-for example, a presenter, musician, or actor.",
     "items": {
      "$ref": "ItemScope"
     }
     },
       "playerType": {
     "type": "string",
     "description": "Player type that is required. For example: Flash or Silverlight."
       },
         "postOfficeBoxNumber": {
     "type": "string",
     "description": "Post office box number."
     },
         "postalCode": {
     "type": "string",
     "description": "Postal code."
     },
         "ratingValue": {
     "type": "string",
     "description": "Rating value."
     },
         "reviewRating": {
     "$ref": "ItemScope",
     "description": "Review rating."
     },
         "startDate": {
     "type": "string",
     "description": "The start date and time of the event (in ISO 8601 date format)."
     },
         "streetAddress": {
     "type": "string",
     "description": "Street address."
     },
         "text": {
     "type": "string",
     "description": "The text that is the result of the app activity. For example, if a user leaves a review of a restaurant, this might be the text of the review."
     },
         "thumbnail": {
     "$ref": "ItemScope",
     "description": "Thumbnail image for an image or video."
     },
         "thumbnailUrl": {
     "type": "string",
     "description": "A URL to a thumbnail image that represents this result."
     },
         "tickerSymbol": {
     "type": "string",
     "description": "The exchange traded instrument associated with a Corporation object. The tickerSymbol is expressed as an exchange and an instrument name separated by a space character. For the exchange component of the tickerSymbol attribute, we reccommend using the controlled vocaulary of Market Identifier Codes (MIC) specified in ISO15022."
     },
         "type": {
     "type": "string",
     "description": "The schema.org URL that best describes the referenced target and matches the type of moment."
     },
         "url": {
     "type": "string",
     "description": "The URL that points to the result object. For example, a permalink directly to a restaurant reviewer's comment."
     },
         "width": {
     "type": "string",
     "description": "The width of the media object."
     },
         "worstRating": {
     "type": "string",
     "description": "Worst possible rating value that a result might obtain. This property defines the lower bound for the ratingValue."
     }
   }
     },
     "Moment": {
   "id": "Moment",
   "type": "object",
   "properties": {
       "id": {
     "type": "string",
     "description": "The moment ID."
       },
         "kind": {
     "type": "string",
     "description": "Identifies this resource as a moment.",
     "default": "plus#moment"
     },
         "result": {
     "$ref": "ItemScope",
     "description": "The object generated by performing the action on the target. For example, a user writes a review of a restaurant, the target is the restaurant and the result is the review."
     },
         "startDate": {
     "type": "string",
     "description": "Time stamp of when the action occurred in RFC3339 format.",
     "format": "date-time"
     },
         "target": {
     "$ref": "ItemScope",
     "description": "The object on which the action was performed.",
     "annotations": {
      "required": [
       "plus.moments.insert"
      ]
     }
     },
       "type": {
     "type": "string",
     "description": "The Google schema for the type of moment to write. For example, http://schemas.google.com/AddActivity.",
     "annotations": {
      "required": [
       "plus.moments.insert"
      ]
     }
       }
   }
     },
     "MomentsFeed": {
   "id": "MomentsFeed",
   "type": "object",
   "properties": {
       "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
       },
         "items": {
     "type": "array",
     "description": "The moments in this page of results.",
     "items": {
      "$ref": "Moment"
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a collection of moments. Value: \"plus#momentsFeed\".",
     "default": "plus#momentsFeed"
       },
         "nextLink": {
     "type": "string",
     "description": "Link to the next page of moments."
     },
         "nextPageToken": {
     "type": "string",
     "description": "The continuation token, which is used to page through large result sets. Provide this value in a subsequent request to return the next page of results."
     },
         "selfLink": {
     "type": "string",
     "description": "Link to this page of moments."
     },
         "title": {
     "type": "string",
     "description": "The title of this collection of moments."
     },
         "updated": {
     "type": "string",
     "description": "The RFC 339 timestamp for when this collection of moments was last updated.",
     "format": "date-time"
     }
   }
     },
     "PeopleFeed": {
   "id": "PeopleFeed",
   "type": "object",
   "properties": {
       "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
       },
         "items": {
     "type": "array",
     "description": "The people in this page of results. Each item includes the id, displayName, image, and url for the person. To retrieve additional profile data, see the people.get method.",
     "items": {
      "$ref": "Person"
     }
     },
       "kind": {
     "type": "string",
     "description": "Identifies this resource as a collection of people. Value: \"plus#peopleFeed\".",
     "default": "plus#peopleFeed"
       },
         "nextPageToken": {
     "type": "string",
     "description": "The continuation token, which is used to page through large result sets. Provide this value in a subsequent request to return the next page of results."
     },
         "selfLink": {
     "type": "string",
     "description": "Link to this resource."
     },
         "title": {
     "type": "string",
     "description": "The title of this collection of people."
     },
         "totalItems": {
     "type": "integer",
     "description": "The total number of people available in this list. The number of people in a response might be smaller due to paging. This might not be set for all collections.",
     "format": "int32"
     }
   }
     },
     "Person": {
   "id": "Person",
   "type": "object",
   "properties": {
       "aboutMe": {
     "type": "string",
     "description": "A short biography for this person."
       },
         "ageRange": {
     "type": "object",
     "description": "The age range of the person.",
     "properties": {
         "max": {
       "type": "integer",
       "description": "The age range's upper bound, if any.",
       "format": "int32"
         },
           "min": {
       "type": "integer",
       "description": "The age range's lower bound, if any.",
       "format": "int32"
       }
     }
     },
       "birthday": {
     "type": "string",
     "description": "The person's date of birth, represented as YYYY-MM-DD."
       },
         "braggingRights": {
     "type": "string",
     "description": "The \"bragging rights\" line of this person."
     },
         "circledByCount": {
     "type": "integer",
     "description": "If a Google+ Page and for followers who are visible, the number of people who have added this page to a circle.",
     "format": "int32"
     },
         "cover": {
     "type": "object",
     "description": "The cover photo content.",
     "properties": {
         "coverInfo": {
       "type": "object",
       "description": "Extra information about the cover photo.",
       "properties": {
           "leftImageOffset": {
         "type": "integer",
         "description": "The difference between the left position of the cover image and the actual displayed cover image. Only valid for banner layout.",
         "format": "int32"
           },
             "topImageOffset": {
         "type": "integer",
         "description": "The difference between the top position of the cover image and the actual displayed cover image. Only valid for banner layout.",
         "format": "int32"
         }
       }
         },
         "coverPhoto": {
       "type": "object",
       "description": "The person's primary cover image.",
       "properties": {
           "height": {
         "type": "integer",
         "description": "The height of the image.",
         "format": "int32"
           },
             "url": {
         "type": "string",
         "description": "The URL of the image."
         },
             "width": {
         "type": "integer",
         "description": "The width of the image.",
         "format": "int32"
         }
       }
         },
         "layout": {
       "type": "string",
       "description": "The layout of the cover art. Possible values include, but are not limited to, the following values:  \n- \"banner\" - One large image banner."
         }
     }
     },
       "currentLocation": {
     "type": "string",
     "description": "The current location for this person."
       },
         "displayName": {
     "type": "string",
     "description": "The name of this person, which is suitable for display."
     },
         "etag": {
     "type": "string",
     "description": "ETag of this response for caching purposes."
     },
         "gender": {
     "type": "string",
     "description": "The person's gender. Possible values include, but are not limited to, the following values:  \n- \"male\" - Male gender. \n- \"female\" - Female gender. \n- \"other\" - Other."
     },
         "id": {
     "type": "string",
     "description": "The ID of this person."
     },
         "image": {
     "type": "object",
     "description": "The representation of the person's profile photo.",
     "properties": {
         "url": {
       "type": "string",
       "description": "The URL of the person's profile photo. To resize the image and crop it to a square, append the query string ?sz=x, where x is the dimension in pixels of each side."
         }
     }
     },
       "isPlusUser": {
     "type": "boolean",
     "description": "Whether this user has signed up for Google+."
       },
         "kind": {
     "type": "string",
     "description": "Identifies this resource as a person. Value: \"plus#person\".",
     "default": "plus#person"
     },
         "language": {
     "type": "string",
     "description": "The user's preferred language for rendering."
     },
         "name": {
     "type": "object",
     "description": "An object representation of the individual components of a person's name.",
     "properties": {
         "familyName": {
       "type": "string",
       "description": "The family name (last name) of this person."
         },
           "formatted": {
       "type": "string",
       "description": "The full name of this person, including middle names, suffixes, etc."
       },
           "givenName": {
       "type": "string",
       "description": "The given name (first name) of this person."
       },
           "honorificPrefix": {
       "type": "string",
       "description": "The honorific prefixes (such as \"Dr.\" or \"Mrs.\") for this person."
       },
           "honorificSuffix": {
       "type": "string",
       "description": "The honorific suffixes (such as \"Jr.\") for this person."
       },
           "middleName": {
       "type": "string",
       "description": "The middle name of this person."
       }
     }
     },
       "nickname": {
     "type": "string",
     "description": "The nickname of this person."
       },
         "objectType": {
     "type": "string",
     "description": "Type of person within Google+. Possible values include, but are not limited to, the following values:  \n- \"person\" - represents an actual person. \n- \"page\" - represents a page."
     },
         "organizations": {
     "type": "array",
     "description": "A list of current or past organizations with which this person is associated.",
     "items": {
      "type": "object",
      "properties": {
          "department": {
        "type": "string",
        "description": "The department within the organization. Deprecated."
          },
            "description": {
        "type": "string",
        "description": "A short description of the person's role in this organization. Deprecated."
        },
            "endDate": {
        "type": "string",
        "description": "The date that the person left this organization."
        },
            "location": {
        "type": "string",
        "description": "The location of this organization. Deprecated."
        },
            "name": {
        "type": "string",
        "description": "The name of the organization."
        },
            "primary": {
        "type": "boolean",
        "description": "If \"true\", indicates this organization is the person's primary one, which is typically interpreted as the current one."
        },
            "startDate": {
        "type": "string",
        "description": "The date that the person joined this organization."
        },
            "title": {
        "type": "string",
        "description": "The person's job title or role within the organization."
        },
            "type": {
        "type": "string",
        "description": "The type of organization. Possible values include, but are not limited to, the following values:  \n- \"work\" - Work. \n- \"school\" - School."
        }
      }
     }
     },
       "placesLived": {
     "type": "array",
     "description": "A list of places where this person has lived.",
     "items": {
      "type": "object",
      "properties": {
          "primary": {
        "type": "boolean",
        "description": "If \"true\", this place of residence is this person's primary residence."
          },
            "value": {
        "type": "string",
        "description": "A place where this person has lived. For example: \"Seattle, WA\", \"Near Toronto\"."
        }
      }
     }
       },
       "plusOneCount": {
     "type": "integer",
     "description": "If a Google+ Page, the number of people who have +1'd this page.",
     "format": "int32"
       },
         "relationshipStatus": {
     "type": "string",
     "description": "The person's relationship status. Possible values include, but are not limited to, the following values:  \n- \"single\" - Person is single. \n- \"in_a_relationship\" - Person is in a relationship. \n- \"engaged\" - Person is engaged. \n- \"married\" - Person is married. \n- \"its_complicated\" - The relationship is complicated. \n- \"open_relationship\" - Person is in an open relationship. \n- \"widowed\" - Person is widowed. \n- \"in_domestic_partnership\" - Person is in a domestic partnership. \n- \"in_civil_union\" - Person is in a civil union."
     },
         "tagline": {
     "type": "string",
     "description": "The brief description (tagline) of this person."
     },
         "url": {
     "type": "string",
     "description": "The URL of this person's profile."
     },
         "urls": {
     "type": "array",
     "description": "A list of URLs for this person.",
     "items": {
      "type": "object",
      "properties": {
          "label": {
        "type": "string",
        "description": "The label of the URL."
          },
            "type": {
        "type": "string",
        "description": "The type of URL. Possible values include, but are not limited to, the following values:  \n- \"otherProfile\" - URL for another profile. \n- \"contributor\" - URL to a site for which this person is a contributor. \n- \"website\" - URL for this Google+ Page's primary website. \n- \"other\" - Other URL."
        },
            "value": {
        "type": "string",
        "description": "The URL value."
        }
      }
     }
     },
       "verified": {
     "type": "boolean",
     "description": "Whether the person or Google+ Page has been verified."
       }
   }
     },
     "Place": {
   "id": "Place",
   "type": "object",
   "properties": {
       "address": {
     "type": "object",
     "description": "The physical address of the place.",
     "properties": {
         "formatted": {
       "type": "string",
       "description": "The formatted address for display."
         }
     }
       },
       "displayName": {
     "type": "string",
     "description": "The display name of the place."
       },
         "kind": {
     "type": "string",
     "description": "Identifies this resource as a place. Value: \"plus#place\".",
     "default": "plus#place"
     },
         "position": {
     "type": "object",
     "description": "The position of the place.",
     "properties": {
         "latitude": {
       "type": "number",
       "description": "The latitude of this position.",
       "format": "double"
         },
           "longitude": {
       "type": "number",
       "description": "The longitude of this position.",
       "format": "double"
       }
     }
     }
   }
     },
     "PlusAclentryResource": {
   "id": "PlusAclentryResource",
   "type": "object",
   "properties": {
       "displayName": {
     "type": "string",
     "description": "A descriptive name for this entry. Suitable for display."
       },
         "id": {
     "type": "string",
     "description": "The ID of the entry. For entries of type \"person\" or \"circle\", this is the ID of the resource. For other types, this property is not set."
     },
         "type": {
     "type": "string",
     "description": "The type of entry describing to whom access is granted. Possible values are:  \n- \"person\" - Access to an individual. \n- \"circle\" - Access to members of a circle. \n- \"myCircles\" - Access to members of all the person's circles. \n- \"extendedCircles\" - Access to members of all the person's circles, plus all of the people in their circles. \n- \"domain\" - Access to members of the person's Google Apps domain. \n- \"public\" - Access to anyone on the web."
     }
   }
     }
 },
 "resources": {
     "activities": {
         "methods": {
             "get": {
     "id": "plus.activities.get",
     "path": "activities/{activityId}",
     "httpMethod": "GET",
     "description": "Get an activity.",
     "parameters": {
         "activityId": {
       "type": "string",
       "description": "The ID of the activity to get.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "activityId"
     ],
      "response": {
      "$ref": "Activity"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
             },
     "list": {
     "id": "plus.activities.list",
     "path": "people/{userId}/activities/{collection}",
     "httpMethod": "GET",
     "description": "List all of the activities in the specified collection for a particular user.",
     "parameters": {
         "collection": {
       "type": "string",
       "description": "The collection of activities to list.",
       "required": true,
       "enum": [
        "public"
       ],
       "enumDescriptions": [
        "All public activities created by the specified user."
       ],
       "location": "path"
         },
       "maxResults": {
       "type": "integer",
       "description": "The maximum number of activities to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "20",
       "format": "uint32",
       "minimum": "1",
       "maximum": "100",
       "location": "query"
   },
           "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response.",
       "location": "query"
       },
           "userId": {
       "type": "string",
       "description": "The ID of the user to get activities for. The special value \"me\" can be used to indicate the authenticated user.",
       "required": true,
       "location": "path"
       }
     },
     "parameterOrder": [
      "userId",
      "collection"
     ],
      "response": {
      "$ref": "ActivityFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
 },
     "search": {
     "id": "plus.activities.search",
     "path": "activities",
     "httpMethod": "GET",
     "description": "Search public activities.",
     "parameters": {
         "language": {
       "type": "string",
       "description": "Specify the preferred language to search with. See search language codes for available values.",
       "default": "en-US",
       "location": "query"
         },
           "maxResults": {
       "type": "integer",
       "description": "The maximum number of activities to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "10",
       "format": "uint32",
       "minimum": "1",
       "maximum": "20",
       "location": "query"
       },
           "orderBy": {
       "type": "string",
       "description": "Specifies how to order search results.",
       "default": "recent",
       "enum": [
        "best",
        "recent"
       ],
       "enumDescriptions": [
        "Sort activities by relevance to the user, most relevant first.",
        "Sort activities by published date, most recent first."
       ],
       "location": "query"
       },
       "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response. This token can be of any length.",
       "location": "query"
   },
           "query": {
       "type": "string",
       "description": "Full-text search query string.",
       "required": true,
       "location": "query"
       }
     },
     "parameterOrder": [
      "query"
     ],
      "response": {
      "$ref": "ActivityFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
 }
         }
     },
     "comments": {
         "methods": {
             "get": {
     "id": "plus.comments.get",
     "path": "comments/{commentId}",
     "httpMethod": "GET",
     "description": "Get a comment.",
     "parameters": {
         "commentId": {
       "type": "string",
       "description": "The ID of the comment to get.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "commentId"
     ],
      "response": {
      "$ref": "Comment"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
             },
     "list": {
     "id": "plus.comments.list",
     "path": "activities/{activityId}/comments",
     "httpMethod": "GET",
     "description": "List all of the comments for an activity.",
     "parameters": {
         "activityId": {
       "type": "string",
       "description": "The ID of the activity to get comments for.",
       "required": true,
       "location": "path"
         },
           "maxResults": {
       "type": "integer",
       "description": "The maximum number of comments to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "20",
       "format": "uint32",
       "minimum": "0",
       "maximum": "500",
       "location": "query"
       },
           "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response.",
       "location": "query"
       },
           "sortOrder": {
       "type": "string",
       "description": "The order in which to sort the list of comments.",
       "default": "ascending",
       "enum": [
        "ascending",
        "descending"
       ],
       "enumDescriptions": [
        "Sort oldest comments first.",
        "Sort newest comments first."
       ],
       "location": "query"
       }
     },
     "parameterOrder": [
      "activityId"
     ],
      "response": {
      "$ref": "CommentFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
 }
         }
     },
     "moments": {
         "methods": {
             "insert": {
     "id": "plus.moments.insert",
     "path": "people/{userId}/moments/{collection}",
     "httpMethod": "POST",
     "description": "Record a moment representing a user's activity such as making a purchase or commenting on a blog.",
     "parameters": {
         "collection": {
       "type": "string",
       "description": "The collection to which to write moments.",
       "required": true,
       "enum": [
        "vault"
       ],
       "enumDescriptions": [
        "The default collection for writing new moments."
       ],
       "location": "path"
         },
       "debug": {
       "type": "boolean",
       "description": "Return the moment as written. Should be used only for debugging.",
       "location": "query"
   },
           "userId": {
       "type": "string",
       "description": "The ID of the user to record activities for. The only valid values are \"me\" and the ID of the authenticated user.",
       "required": true,
       "location": "path"
       }
     },
     "parameterOrder": [
      "userId",
      "collection"
     ],
      "request": {
      "$ref": "Moment"
  },
          "response": {
      "$ref": "Moment"
      },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login"
     ]
             },
     "list": {
     "id": "plus.moments.list",
     "path": "people/{userId}/moments/{collection}",
     "httpMethod": "GET",
     "description": "List all of the moments for a particular user.",
     "parameters": {
         "collection": {
       "type": "string",
       "description": "The collection of moments to list.",
       "required": true,
       "enum": [
        "vault"
       ],
       "enumDescriptions": [
        "All moments created by the requesting application for the authenticated user."
       ],
       "location": "path"
         },
       "maxResults": {
       "type": "integer",
       "description": "The maximum number of moments to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "20",
       "format": "uint32",
       "minimum": "1",
       "maximum": "100",
       "location": "query"
   },
           "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response.",
       "location": "query"
       },
           "targetUrl": {
       "type": "string",
       "description": "Only moments containing this targetUrl will be returned.",
       "location": "query"
       },
           "type": {
       "type": "string",
       "description": "Only moments of this type will be returned.",
       "location": "query"
       },
           "userId": {
       "type": "string",
       "description": "The ID of the user to get moments for. The special value \"me\" can be used to indicate the authenticated user.",
       "required": true,
       "location": "path"
       }
     },
     "parameterOrder": [
      "userId",
      "collection"
     ],
      "response": {
      "$ref": "MomentsFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login"
     ]
 },
     "remove": {
     "id": "plus.moments.remove",
     "path": "moments/{id}",
     "httpMethod": "DELETE",
     "description": "Delete a moment.",
     "parameters": {
         "id": {
       "type": "string",
       "description": "The ID of the moment to delete.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "id"
     ],
     "scopes": [
      "https://www.googleapis.com/auth/plus.login"
     ]
 }
         }
     },
     "people": {
         "methods": {
             "get": {
     "id": "plus.people.get",
     "path": "people/{userId}",
     "httpMethod": "GET",
     "description": "Get a person's profile. If your app uses scope https://www.googleapis.com/auth/plus.login, this method is guaranteed to return ageRange and language.",
     "parameters": {
         "userId": {
       "type": "string",
       "description": "The ID of the person to get the profile for. The special value \"me\" can be used to indicate the authenticated user.",
       "required": true,
       "location": "path"
         }
     },
     "parameterOrder": [
      "userId"
     ],
      "response": {
      "$ref": "Person"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
             },
     "list": {
     "id": "plus.people.list",
     "path": "people/{userId}/people/{collection}",
     "httpMethod": "GET",
     "description": "List all of the people in the specified collection.",
     "parameters": {
         "collection": {
       "type": "string",
       "description": "The collection of people to list.",
       "required": true,
       "enum": [
        "visible"
       ],
       "enumDescriptions": [
        "The list of people who this user has added to one or more circles, limited to the circles visible to the requesting application."
       ],
       "location": "path"
         },
       "maxResults": {
       "type": "integer",
       "description": "The maximum number of people to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "100",
       "format": "uint32",
       "minimum": "1",
       "maximum": "100",
       "location": "query"
   },
           "orderBy": {
       "type": "string",
       "description": "The order to return people in.",
       "enum": [
        "alphabetical",
        "best"
       ],
       "enumDescriptions": [
        "Order the people by their display name.",
        "Order people based on the relevence to the viewer."
       ],
       "location": "query"
       },
       "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response.",
       "location": "query"
   },
           "userId": {
       "type": "string",
       "description": "Get the collection of people for the person identified. Use \"me\" to indicate the authenticated user.",
       "required": true,
       "location": "path"
       }
     },
     "parameterOrder": [
      "userId",
      "collection"
     ],
      "response": {
      "$ref": "PeopleFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login"
     ]
 },
     "listByActivity": {
     "id": "plus.people.listByActivity",
     "path": "activities/{activityId}/people/{collection}",
     "httpMethod": "GET",
     "description": "List all of the people in the specified collection for a particular activity.",
     "parameters": {
         "activityId": {
       "type": "string",
       "description": "The ID of the activity to get the list of people for.",
       "required": true,
       "location": "path"
         },
           "collection": {
       "type": "string",
       "description": "The collection of people to list.",
       "required": true,
       "enum": [
        "plusoners",
        "resharers"
       ],
       "enumDescriptions": [
        "List all people who have +1'd this activity.",
        "List all people who have reshared this activity."
       ],
       "location": "path"
       },
       "maxResults": {
       "type": "integer",
       "description": "The maximum number of people to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "20",
       "format": "uint32",
       "minimum": "1",
       "maximum": "100",
       "location": "query"
   },
           "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response.",
       "location": "query"
       }
     },
     "parameterOrder": [
      "activityId",
      "collection"
     ],
      "response": {
      "$ref": "PeopleFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
 },
     "search": {
     "id": "plus.people.search",
     "path": "people",
     "httpMethod": "GET",
     "description": "Search all public profiles.",
     "parameters": {
         "language": {
       "type": "string",
       "description": "Specify the preferred language to search with. See search language codes for available values.",
       "default": "en-US",
       "location": "query"
         },
           "maxResults": {
       "type": "integer",
       "description": "The maximum number of people to include in the response, which is used for paging. For any response, the actual number returned might be less than the specified maxResults.",
       "default": "25",
       "format": "uint32",
       "minimum": "1",
       "maximum": "50",
       "location": "query"
       },
           "pageToken": {
       "type": "string",
       "description": "The continuation token, which is used to page through large result sets. To get the next page of results, set this parameter to the value of \"nextPageToken\" from the previous response. This token can be of any length.",
       "location": "query"
       },
           "query": {
       "type": "string",
       "description": "Specify a query string for full text search of public text in all profiles.",
       "required": true,
       "location": "query"
       }
     },
     "parameterOrder": [
      "query"
     ],
      "response": {
      "$ref": "PeopleFeed"
  },
     "scopes": [
      "https://www.googleapis.com/auth/plus.login",
      "https://www.googleapis.com/auth/plus.me"
     ]
 }
         }
     }
 }
}

EOF

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Google::API::Client - A client for Google APIs Discovery Service

=head1 SYNOPSIS

  use Google::API::Client;

  my $client = Google::API::Client->new;
  my $service = $client->build('urlshortener', 'v1');

  # Get shortened URL 
  my $body = {
      'longUrl' => 'http://code.google.com/apis/urlshortener/',
  };
  my $result = $url->insert(body => $body)->execute;
  $result->{id}; # shortened URL

=head1 DESCRIPTION

Google::API::Client is a client for Google APIs Discovery Service. You make using Google APIs easy.

=head1 METHODS

=over 4

=item new

=item build

=item build_from_document

=back

=head1 AUTHOR

Takatsugu Shigeta E<lt>shigeta@cpan.orgE<gt>

=head1 CONTRIBUTORS

Yusuke Ueno (uechoco)

Gustavo Chaves (gnustavo)

Hatsuhito UENO (uehatsu)

=head1 COPYRIGHT

Copyright 2011- Takatsugu Shigeta

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
