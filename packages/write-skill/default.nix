{
  lib,
  runCommand,
  skills-ref,
  ste-lint,
}:
# Build an Agent Skill directory and validate it in the same build, in the
# spirit of pkgs.writers: the checks ride on the artifact, so an invalid
# skill is never produced in the first place.
#
# name: the skill name. Must obey the spec's name rules; also becomes the
#   store name and the directory the harnesses install to.
# src: directory containing the skill files (SKILL.md, references/, ...).
#
# Options:
#   lint (default true): run the STE prose linter on SKILL.md. Set to false
#     for skills whose body is pinned third-party content; the linter is for
#     prose this repository maintains.
name:
{
  lint ? true,
}:
src:
runCommand name
  {
    nativeBuildInputs = [ skills-ref ] ++ lib.optionals lint [ ste-lint ];
  }
  (
    # skills-ref checks the directory basename against the frontmatter name,
    # and store paths carry a hash prefix, so validate a clean-named copy.
    # This is also the layout the harnesses install.
    ''
      mkdir work
      cp -r "${src}" "work/${name}"
      chmod -R u+w "work/${name}"
      skills-ref validate "work/${name}"
    ''
    + lib.optionalString lint ''
      # Prose check: SKILL.md must pass the STE linter with zero hard
      # violations; advisory findings (passive voice, compound tenses) do not
      # fail the build.
      ste-lint "work/${name}/SKILL.md"
    ''
    + ''
      cp -r "work/${name}" "$out"
    ''
  )
