//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

BOOL IsNoteToSelfEnabled(void);

@class OWSDisappearingMessagesConfiguration;
@class SDSAnyReadTransaction;
@class SDSAnyWriteTransaction;
@class SignalServiceAddress;
@class TSInteraction;
@class TSInvalidIdentityKeyReceivingErrorMessage;

typedef NSString *ConversationColorName NS_STRING_ENUM;

extern ConversationColorName const ConversationColorNameCrimson;
extern ConversationColorName const ConversationColorNameVermilion;
extern ConversationColorName const ConversationColorNameBurlap;
extern ConversationColorName const ConversationColorNameForest;
extern ConversationColorName const ConversationColorNameWintergreen;
extern ConversationColorName const ConversationColorNameTeal;
extern ConversationColorName const ConversationColorNameBlue;
extern ConversationColorName const ConversationColorNameIndigo;
extern ConversationColorName const ConversationColorNameViolet;
extern ConversationColorName const ConversationColorNamePlum;
extern ConversationColorName const ConversationColorNameTaupe;
extern ConversationColorName const ConversationColorNameSteel;

extern ConversationColorName const kConversationColorName_Default;

/**
 *  TSThread is the superclass of TSContactThread and TSGroupThread
 */
@interface TSThread : BaseModel

@property (nonatomic) BOOL shouldThreadBeVisible;
@property (nonatomic, readonly, nullable) NSDate *creationDate;
@property (nonatomic, readonly) BOOL isArchivedByLegacyTimestampForSorting DEPRECATED_MSG_ATTRIBUTE("this property is only to be used in the sortId migration");
@property (nonatomic, readonly) BOOL isArchived;

// zero if thread has never had an interaction.
// The corresponding interaction may have been deleted.
@property (nonatomic, readonly) int64_t lastInteractionRowId;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
           conversationColorName:(ConversationColorName)conversationColorName
                    creationDate:(nullable NSDate *)creationDate
                      isArchived:(BOOL)isArchived
            lastInteractionRowId:(int64_t)lastInteractionRowId
                    messageDraft:(nullable NSString *)messageDraft
                  mutedUntilDate:(nullable NSDate *)mutedUntilDate
           shouldThreadBeVisible:(BOOL)shouldThreadBeVisible
NS_SWIFT_NAME(init(grdbId:uniqueId:conversationColorName:creationDate:isArchived:lastInteractionRowId:messageDraft:mutedUntilDate:shouldThreadBeVisible:));

// clang-format on

// --- CODE GENERATION MARKER

/**
 *  Whether the object is a group thread or not.
 *
 *  @return YES if is a group thread, NO otherwise.
 */
- (BOOL)isGroupThread;

@property (nonatomic) ConversationColorName conversationColorName;

- (void)updateConversationColorName:(ConversationColorName)colorName transaction:(SDSAnyWriteTransaction *)transaction;
+ (ConversationColorName)stableColorNameForNewConversationWithString:(NSString *)colorSeed;
@property (class, nonatomic, readonly) NSArray<ConversationColorName> *conversationColorNames;

/**
 * @returns recipientId for each recipient in the thread
 */
@property (nonatomic, readonly) NSArray<SignalServiceAddress *> *recipientAddresses;

@property (nonatomic, readonly) BOOL isNoteToSelf;

#pragma mark Interactions

/**
 *  @return The number of interactions in this thread.
 */
- (NSUInteger)numberOfInteractionsWithTransaction:(SDSAnyReadTransaction *)transaction;

/**
 * Get all messages in the thread we weren't able to decrypt
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSArray<TSInvalidIdentityKeyReceivingErrorMessage *> *)receivedMessagesForInvalidKey:(NSData *)key;
#pragma clang diagnostic pop

- (BOOL)hasSafetyNumbers;

- (void)markAllAsReadWithTransaction:(SDSAnyWriteTransaction *)transaction;

/**
 *  Returns the string that will be displayed typically in a conversations view as a preview of the last message
 *received in this thread.
 *
 *  @return Thread preview string.
 */
- (NSString *)lastMessageTextWithTransaction:(SDSAnyReadTransaction *)transaction
    NS_SWIFT_NAME(lastMessageText(transaction:));

- (nullable TSInteraction *)lastInteractionForInboxWithTransaction:(SDSAnyReadTransaction *)transaction
    NS_SWIFT_NAME(lastInteractionForInbox(transaction:));

/**
 *  Updates the thread's caches of the latest interaction.
 *
 *  @param message Latest Interaction to take into consideration.
 *  @param transaction Database transaction.
 */
- (void)updateWithInsertedMessage:(TSInteraction *)message transaction:(SDSAnyWriteTransaction *)transaction;
- (void)updateWithUpdatedMessage:(TSInteraction *)message transaction:(SDSAnyWriteTransaction *)transaction;
- (void)updateWithRemovedMessage:(TSInteraction *)message transaction:(SDSAnyWriteTransaction *)transaction;

#pragma mark Archival

/**
 *  Archives a thread
 *
 *  @param transaction Database transaction.
 */
- (void)archiveThreadWithTransaction:(SDSAnyWriteTransaction *)transaction;

- (void)softDeleteThreadWithTransaction:(SDSAnyWriteTransaction *)transaction;

/**
 *  Unarchives a thread
 *
 *  @param transaction Database transaction.
 */
- (void)unarchiveThreadWithTransaction:(SDSAnyWriteTransaction *)transaction;

- (void)removeAllThreadInteractionsWithTransaction:(SDSAnyWriteTransaction *)transaction;


#pragma mark Disappearing Messages

- (OWSDisappearingMessagesConfiguration *)disappearingMessagesConfigurationWithTransaction:
    (SDSAnyReadTransaction *)transaction;
- (uint32_t)disappearingMessagesDurationWithTransaction:(SDSAnyReadTransaction *)transaction;

#pragma mark Drafts

/**
 *  Returns the last known draft for that thread. Always returns a string. Empty string if nil.
 *
 *  @param transaction Database transaction.
 *
 *  @return Last known draft for that thread.
 */
- (NSString *)currentDraftWithTransaction:(SDSAnyReadTransaction *)transaction;

/**
 *  Sets the draft of a thread. Typically called when leaving a conversation view.
 *
 *  @param draftString Draft string to be saved.
 *  @param transaction Database transaction.
 */
- (void)updateWithDraft:(NSString *)draftString transaction:(SDSAnyWriteTransaction *)transaction;

@property (atomic, readonly) BOOL isMuted;
@property (atomic, readonly, nullable) NSDate *mutedUntilDate;

#pragma mark - Update With... Methods

- (void)updateWithMutedUntilDate:(NSDate *)mutedUntilDate transaction:(SDSAnyWriteTransaction *)transaction;

+ (BOOL)shouldInteractionAppearInInbox:(TSInteraction *)interaction;

@end

NS_ASSUME_NONNULL_END
