#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DISTROS=${DISTROS:-"fedora rockylinux centos-stream ubuntu alpine"}
MODES=${MODES:-"minimal"}
CLEAN=${CLEAN:-false}

# Help function
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Test dotfiles installation in Docker containers for multiple distributions.

OPTIONS:
    -d, --distros DISTROS    Distributions to test (default: "fedora rockylinux centos-stream ubuntu alpine")
    -m, --modes MODES        Installation modes to test (default: "minimal")
                            Available: minimal, devops, development, desktop
    -c, --clean             Clean up containers and images after testing
    -h, --help              Show this help message

EXAMPLES:
    # Test minimal installation on all distributions
    $0

    # Test all modes on Fedora
    $0 -d fedora -m "minimal devops development"

    # Test specific combination and clean up
    $0 -d "fedora rockylinux" -m "minimal devops" -c

    # Test single distro and mode
    $0 -d fedora -m development
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--distros)
            DISTROS="$2"
            shift 2
            ;;
        -m|--modes)
            MODES="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Change to docker test directory
cd "$(dirname "$0")"

# Test results storage
declare -A test_results
failed_tests=0
total_tests=0

# Function to run test
run_test() {
    local distro=$1
    local mode=$2
    local test_name="${distro}-${mode}"

    total_tests=$((total_tests + 1))

    echo -e "\n${BLUE}=== Testing ${distro} with ${mode} mode ===${NC}"

    # Build the Docker image
    echo -e "${YELLOW}Building Docker image for ${test_name}...${NC}"
    if docker-compose build ${test_name} 2>&1 | tee build-${test_name}.log; then
        echo -e "${GREEN}✓ Build successful for ${test_name}${NC}"

        # Run basic tests in the container
        echo -e "${YELLOW}Running tests in ${test_name}...${NC}"
        if docker-compose run --rm ${test_name} -c "
            set -e
            # Check if zsh is installed
            which zsh >/dev/null 2>&1 || exit 1
            # Check if git is configured
            git config --get user.name >/dev/null 2>&1 || exit 1
            # Check if dotfiles are linked
            [[ -f ~/.zshrc ]] || exit 1
            [[ -f ~/.gitconfig ]] || exit 1
            echo 'All basic tests passed!'
        " 2>&1 | tee test-${test_name}.log; then
            echo -e "${GREEN}✓ Tests passed for ${test_name}${NC}"
            test_results[${test_name}]="PASSED"
        else
            echo -e "${RED}✗ Tests failed for ${test_name}${NC}"
            test_results[${test_name}]="FAILED"
            failed_tests=$((failed_tests + 1))
        fi
    else
        echo -e "${RED}✗ Build failed for ${test_name}${NC}"
        test_results[${test_name}]="BUILD_FAILED"
        failed_tests=$((failed_tests + 1))
    fi
}

# Main test loop
echo -e "${BLUE}Starting dotfiles tests...${NC}"
echo "Distributions: ${DISTROS}"
echo "Modes: ${MODES}"
echo ""

for distro in ${DISTROS}; do
    for mode in ${MODES}; do
        # Map distro name to dockerfile name if needed
        dockerfile_distro=${distro}
        if [[ "${distro}" == "rockylinux" ]]; then
            dockerfile_distro="rocky"
        elif [[ "${distro}" == "centos-stream" ]]; then
            dockerfile_distro="centos-stream"
        fi

        run_test ${dockerfile_distro} ${mode}
    done
done

# Print summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo "Total tests: ${total_tests}"
echo "Failed tests: ${failed_tests}"
echo ""

for test_name in "${!test_results[@]}"; do
    result=${test_results[${test_name}]}
    if [[ "${result}" == "PASSED" ]]; then
        echo -e "${GREEN}✓ ${test_name}: ${result}${NC}"
    else
        echo -e "${RED}✗ ${test_name}: ${result}${NC}"
    fi
done | sort

# Clean up if requested
if [[ "${CLEAN}" == "true" ]]; then
    echo -e "\n${YELLOW}Cleaning up containers and images...${NC}"
    docker-compose down --rmi all --volumes --remove-orphans
    echo -e "${GREEN}✓ Cleanup completed${NC}"
fi

# Exit with appropriate code
if [[ ${failed_tests} -gt 0 ]]; then
    echo -e "\n${RED}Some tests failed. Check the logs for details.${NC}"
    exit 1
else
    echo -e "\n${GREEN}All tests passed successfully!${NC}"
    exit 0
fi