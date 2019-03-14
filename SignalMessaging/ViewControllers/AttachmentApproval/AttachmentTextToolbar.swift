//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import UIKit

// Coincides with Android's max text message length
let kMaxMessageBodyCharacterCount = 2000

protocol AttachmentTextToolbarDelegate: class {
    func attachmentTextToolbarDidTapSend(_ attachmentTextToolbar: AttachmentTextToolbar)
    func attachmentTextToolbarDidBeginEditing(_ attachmentTextToolbar: AttachmentTextToolbar)
    func attachmentTextToolbarDidEndEditing(_ attachmentTextToolbar: AttachmentTextToolbar)
    func attachmentTextToolbarDidAddMore(_ attachmentTextToolbar: AttachmentTextToolbar)
}

// MARK: -

class AttachmentTextToolbar: UIView, UITextViewDelegate {

    weak var attachmentTextToolbarDelegate: AttachmentTextToolbarDelegate?

    var messageText: String? {
        get { return textView.text }

        set {
            textView.text = newValue
            updatePlaceholderTextViewVisibility()
        }
    }

    // Layout Constants

    let kMinTextViewHeight: CGFloat = 38
    var maxTextViewHeight: CGFloat {
        // About ~4 lines in portrait and ~3 lines in landscape.
        // Otherwise we risk obscuring too much of the content.
        return UIDevice.current.orientation.isPortrait ? 160 : 100
    }
    var textViewHeightConstraint: NSLayoutConstraint!
    var textViewHeight: CGFloat

    // MARK: - Initializers

    init(isAddMoreVisible: Bool) {
        self.addMoreButton = UIButton(type: .custom)
        self.sendButton = UIButton(type: .system)
        self.textViewHeight = kMinTextViewHeight

        super.init(frame: CGRect.zero)

        // Specifying autorsizing mask and an intrinsic content size allows proper
        // sizing when used as an input accessory view.
        self.autoresizingMask = .flexibleHeight
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.clear

        textView.delegate = self

        let addMoreIcon = #imageLiteral(resourceName: "album_add_more").withRenderingMode(.alwaysTemplate)
        addMoreButton.setImage(addMoreIcon, for: .normal)
        addMoreButton.tintColor = Theme.darkThemePrimaryColor
        addMoreButton.addTarget(self, action: #selector(didTapAddMore), for: .touchUpInside)

        let sendTitle = NSLocalizedString("ATTACHMENT_APPROVAL_SEND_BUTTON", comment: "Label for 'send' button in the 'attachment approval' dialog.")
        sendButton.setTitle(sendTitle, for: .normal)
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        sendButton.titleLabel?.font = UIFont.ows_mediumFont(withSize: 16)
        sendButton.titleLabel?.textAlignment = .center
        sendButton.tintColor = Theme.galleryHighlightColor

        // Increase hit area of send button
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

        let contentView = UIView()
        contentView.addSubview(sendButton)
        contentView.addSubview(textContainer)
        contentView.addSubview(lengthLimitLabel)
        if isAddMoreVisible {
            contentView.addSubview(addMoreButton)
        }

        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges()

        // Layout
        let kToolbarMargin: CGFloat = 8

        // We have to wrap the toolbar items in a content view because iOS (at least on iOS10.3) assigns the inputAccessoryView.layoutMargins
        // when resigning first responder (verified by auditing with `layoutMarginsDidChange`).
        // The effect of this is that if we were to assign these margins to self.layoutMargins, they'd be blown away if the
        // user dismisses the keyboard, giving the input accessory view a wonky layout.
        contentView.layoutMargins = UIEdgeInsets(top: kToolbarMargin, left: kToolbarMargin, bottom: kToolbarMargin, right: kToolbarMargin)

        self.textViewHeightConstraint = textView.autoSetDimension(.height, toSize: kMinTextViewHeight)

        // We pin all three edges explicitly rather than doing something like:
        //  textView.autoPinEdges(toSuperviewMarginsExcludingEdge: .right)
        // because that method uses `leading` / `trailing` rather than `left` vs. `right`.
        // So it doesn't work as expected with RTL layouts when we explicitly want something
        // to be on the right side for both RTL and LTR layouts, like with the send button.
        // I believe this is a bug in PureLayout. Filed here: https://github.com/PureLayout/PureLayout/issues/209
        textContainer.autoPinEdge(toSuperviewMargin: .top)
        textContainer.autoPinEdge(toSuperviewMargin: .bottom)
        if isAddMoreVisible {
            addMoreButton.autoPinEdge(toSuperviewMargin: .left)
            textContainer.autoPinEdge(.left, to: .right, of: addMoreButton, withOffset: kToolbarMargin)
            addMoreButton.autoAlignAxis(.horizontal, toSameAxisOf: sendButton)
            addMoreButton.setContentHuggingHigh()
            addMoreButton.setCompressionResistanceHigh()
        } else {
            textContainer.autoPinEdge(toSuperviewMargin: .left)
        }

        sendButton.autoPinEdge(.left, to: .right, of: textContainer, withOffset: kToolbarMargin)
        sendButton.autoPinEdge(.bottom, to: .bottom, of: textContainer, withOffset: -3)

        sendButton.autoPinEdge(toSuperviewMargin: .right)
        sendButton.setContentHuggingHigh()
        sendButton.setCompressionResistanceHigh()

        lengthLimitLabel.autoPinEdge(toSuperviewMargin: .left)
        lengthLimitLabel.autoPinEdge(toSuperviewMargin: .right)
        lengthLimitLabel.autoPinEdge(.bottom, to: .top, of: textContainer, withOffset: -6)
        lengthLimitLabel.setContentHuggingHigh()
        lengthLimitLabel.setCompressionResistanceHigh()
    }

    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    // MARK: - UIView Overrides

    override var intrinsicContentSize: CGSize {
        get {
            // Since we have `self.autoresizingMask = UIViewAutoresizingFlexibleHeight`, we must specify
            // an intrinsicContentSize. Specifying CGSize.zero causes the height to be determined by autolayout.
            return CGSize.zero
        }
    }

    // MARK: - Subviews

    private let addMoreButton: UIButton
    private let sendButton: UIButton

    private lazy var lengthLimitLabel: UILabel = {
        let lengthLimitLabel = UILabel()

        // Length Limit Label shown when the user inputs too long of a message
        lengthLimitLabel.textColor = .white
        lengthLimitLabel.text = NSLocalizedString("ATTACHMENT_APPROVAL_MESSAGE_LENGTH_LIMIT_REACHED", comment: "One-line label indicating the user can add no more text to the media message field.")
        lengthLimitLabel.textAlignment = .center

        // Add shadow in case overlayed on white content
        lengthLimitLabel.layer.shadowColor = UIColor.black.cgColor
        lengthLimitLabel.layer.shadowOffset = .zero
        lengthLimitLabel.layer.shadowOpacity = 0.8
        lengthLimitLabel.layer.shadowRadius = 2.0
        lengthLimitLabel.isHidden = true

        return lengthLimitLabel
    }()

    lazy var textView: UITextView = {
        let textView = buildTextView()

        textView.returnKeyType = .done
        textView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 3)

        return textView
    }()

    private lazy var placeholderTextView: UITextView = {
        let placeholderTextView = buildTextView()

        placeholderTextView.text = NSLocalizedString("MESSAGE_TEXT_FIELD_PLACEHOLDER", comment: "placeholder text for the editable message field")
        placeholderTextView.isEditable = false

        return placeholderTextView
    }()

    private lazy var textContainer: UIView = {
        let textContainer = UIView()

        textContainer.layer.borderColor = Theme.darkThemePrimaryColor.cgColor
        textContainer.layer.borderWidth = 0.5
        textContainer.layer.cornerRadius = kMinTextViewHeight / 2
        textContainer.clipsToBounds = true

        textContainer.addSubview(placeholderTextView)
        placeholderTextView.autoPinEdgesToSuperviewEdges()

        textContainer.addSubview(textView)
        textView.autoPinEdgesToSuperviewEdges()

        return textContainer
    }()

    private func buildTextView() -> UITextView {
        let textView = AttachmentTextView()

        textView.keyboardAppearance = Theme.darkThemeKeyboardAppearance
        textView.backgroundColor = .clear
        textView.tintColor = Theme.darkThemePrimaryColor

        textView.font = UIFont.ows_dynamicTypeBody
        textView.textColor = Theme.darkThemePrimaryColor
        textView.textContainerInset = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)

        return textView
    }

    // MARK: - Actions

    @objc func didTapSend() {
        attachmentTextToolbarDelegate?.attachmentTextToolbarDidTapSend(self)
    }

    @objc func didTapAddMore() {
        attachmentTextToolbarDelegate?.attachmentTextToolbarDidAddMore(self)
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        updateHeight(textView: textView)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if !FeatureFlags.sendingMediaWithOversizeText {
            let existingText: String = textView.text ?? ""
            let proposedText: String = (existingText as NSString).replacingCharacters(in: range, with: text)

            // Don't complicate things by mixing media attachments with oversize text attachments
            guard proposedText.utf8.count < kOversizeTextMessageSizeThreshold else {
                Logger.debug("long text was truncated")
                self.lengthLimitLabel.isHidden = false

                // `range` represents the section of the existing text we will replace. We can re-use that space.
                // Range is in units of NSStrings's standard UTF-16 characters. Since some of those chars could be
                // represented as single bytes in utf-8, while others may be 8 or more, the only way to be sure is
                // to just measure the utf8 encoded bytes of the replaced substring.
                let bytesAfterDelete: Int = (existingText as NSString).replacingCharacters(in: range, with: "").utf8.count

                // Accept as much of the input as we can
                let byteBudget: Int = Int(kOversizeTextMessageSizeThreshold) - bytesAfterDelete
                if byteBudget >= 0, let acceptableNewText = text.truncated(toByteCount: UInt(byteBudget)) {
                    textView.text = (existingText as NSString).replacingCharacters(in: range, with: acceptableNewText)
                }

                return false
            }
            self.lengthLimitLabel.isHidden = true

            // After verifying the byte-length is sufficiently small, verify the character count is within bounds.
            guard proposedText.count < kMaxMessageBodyCharacterCount else {
                Logger.debug("hit attachment message body character count limit")

                self.lengthLimitLabel.isHidden = false

                // `range` represents the section of the existing text we will replace. We can re-use that space.
                let charsAfterDelete: Int = (existingText as NSString).replacingCharacters(in: range, with: "").count

                // Accept as much of the input as we can
                let charBudget: Int = Int(kMaxMessageBodyCharacterCount) - charsAfterDelete
                if charBudget >= 0 {
                    let acceptableNewText = String(text.prefix(charBudget))
                    textView.text = (existingText as NSString).replacingCharacters(in: range, with: acceptableNewText)
                }

                return false
            }
        }

        // Though we can wrap the text, we don't want to encourage multline captions, plus a "done" button
        // allows the user to get the keyboard out of the way while in the attachment approval view.
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        attachmentTextToolbarDelegate?.attachmentTextToolbarDidBeginEditing(self)
        updatePlaceholderTextViewVisibility()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        attachmentTextToolbarDelegate?.attachmentTextToolbarDidEndEditing(self)
        updatePlaceholderTextViewVisibility()
    }

    // MARK: - Helpers

    func updatePlaceholderTextViewVisibility() {
        let isHidden: Bool = {
            guard !self.textView.isFirstResponder else {
                return true
            }

            guard let text = self.textView.text else {
                return false
            }

            guard text.count > 0 else {
                return false
            }

            return true
        }()

        placeholderTextView.isHidden = isHidden
    }

    private func updateHeight(textView: UITextView) {
        // compute new height assuming width is unchanged
        let currentSize = textView.frame.size
        let newHeight = clampedTextViewHeight(fixedWidth: currentSize.width)

        if newHeight != textViewHeight {
            Logger.debug("TextView height changed: \(textViewHeight) -> \(newHeight)")
            textViewHeight = newHeight
            textViewHeightConstraint?.constant = textViewHeight
            invalidateIntrinsicContentSize()
        }
    }

    private func clampedTextViewHeight(fixedWidth: CGFloat) -> CGFloat {
        let contentSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        return CGFloatClamp(contentSize.height, kMinTextViewHeight, maxTextViewHeight)
    }
}