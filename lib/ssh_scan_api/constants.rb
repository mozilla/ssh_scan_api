module SSHScan
  module Api
    module Constants
      CONTRIBUTE_JSON = {
        :name => "ssh_scan api",
        :description => "An api for performing ssh compliance \
  and policy scanning",
        :repository => {
          :url => "https://github.com/mozilla/ssh_scan",
          :tests => "https://travis-ci.org/mozilla/ssh_scan",
        },
        :participate => {
          :home => "https://github.com/mozilla/ssh_scan",
          :docs => "https://github.com/mozilla/ssh_scan",
          :irc => "irc://irc.mozilla.org/#infosec",
          :irc_contacts => [
            "claudijd",
            "pwnbus",
            "kang",
          ],
          :gitter => "https://gitter.im/mozilla-ssh_scan/Lobby",
          :gitter_contacts => [
            "claudijd",
            "pwnbus",
            "kang",
            "jinankjain",
            "agaurav77"
          ],
        },
        :bugs => {
          :list => "https://github.com/mozilla/ssh_scan/issues",
        },
        :keywords => [
          "ruby",
          "sinatra",
        ],
        :urls => {
          :dev => "https://sshscan.rubidus.com",
        }
      }.freeze

      VALID_CHAR_LIST = (("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a + [":", ".", "-"]).freeze
    
      INVALID_TARGET_REGEXES = [
        '^127\.', # Forbid IPv4 localhosts
        '^::1',    # Forbid IPv6 localhosts
        '^10\.', # Forbid RFC1918
        '^192\.168', # Forbid RFC1918
        '^172\.(1[6-9]|2[0-9]|3[0-1])' # Forbid RFC1918
      ].freeze

      INVALID_TARGET_STRINGS = [
        'localhost',               # Forbid localhost ref verbatim
        'notallowed.example.com',  # an FQDN example, so we know can prevent a FQDN from being scanned for whatever reason
      ].freeze
    end
  end
end
