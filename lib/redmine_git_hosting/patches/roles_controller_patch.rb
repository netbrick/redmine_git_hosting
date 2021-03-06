require_dependency 'roles_controller'

module RedmineGitHosting
  module Patches
    module RolesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :create,      :git_hosting
          alias_method_chain :update,      :git_hosting
          alias_method_chain :destroy,     :git_hosting
          alias_method_chain :permissions, :git_hosting
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          # Do actual update
          create_without_git_hosting(&block)
          resync_gitolite('created')
        end


        def update_with_git_hosting(&block)
          # Do actual update
          update_without_git_hosting(&block)
          resync_gitolite('modified')
        end


        def destroy_with_git_hosting(&block)
          # Do actual update
          destroy_without_git_hosting(&block)
          resync_gitolite('deleted')
        end


        def permissions_with_git_hosting(&block)
          # Do actual update
          permissions_without_git_hosting(&block)

          if request.post?
            resync_gitolite('modified')
          end
        end


        private


        def resync_gitolite(message)
          RedmineGitolite::GitHosting.logger.info { "Role has been #{message}, resync all projects (active or closed)..." }
          RedmineGitolite::GitHosting.resync_gitolite(:update_projects, 'active_or_closed')
        end

      end

    end
  end
end

unless RolesController.included_modules.include?(RedmineGitHosting::Patches::RolesControllerPatch)
  RolesController.send(:include, RedmineGitHosting::Patches::RolesControllerPatch)
end
